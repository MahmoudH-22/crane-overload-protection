/**
 * @file crane_link.h
 * @brief Uno <-> NodeMCU serial protocol, shared by both sketches (keep the two copies identical:
 *        firmware/uno/crane_uno_m2/crane_link.h and firmware/nodemcu/crane_nodemcu/crane_link.h).
 *
 * Plain C++ with no Arduino dependency, so it is unit-tested on the laptop (firmware/test/).
 *
 * Since 21-11-2026 the Uno talks to the phone through an HC-05 (Bluetooth serial) and the app parses these
 * lines itself: app/lib/features/connection/data/crane_link_codec.dart is the Dart port; keep it in step.
 *
 * Every line is "<body>*XX\n", XX = XOR of the body bytes in hex. Fields are comma separated;
 * an EMPTY field means "no value" (sensor not fitted or no reading) and becomes JSON null.
 *
 * Uno -> NodeMCU
 *   L,t,kg,max,h,a,top,st,mode,src,us,obs   live sample, every 200 ms          -> crane/live
 *   A,id,ok,reason                           command result / refusal           -> crane/ack
 *   E,t,type,kg                              event                              -> crane/events
 *   S,<sensors>                              fitted sensors, space separated,   -> crane/status
 *                                            e.g. "S,kg top" (every 2 s)
 * NodeMCU -> Uno
 *   C,id,CMD[,value]                         app command (LIFT, LOWER, GOTO, STOP, RESET, TARE, SET_MAX, PING)
 */
#pragma once
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

namespace crane_link {

/** Longest line (body + "*XX\n" + NUL) either side sends. */
const size_t MAX_LINE = 96;

/** Most fields in one line (the L line has 12). */
const uint8_t MAX_FIELDS = 14;

/**
 * XOR checksum of a character range.
 * @param s Text.
 * @param n Number of characters.
 * @return 8-bit checksum.
 */
inline uint8_t xorSum(const char* s, size_t n) {
  uint8_t c = 0;
  for (size_t i = 0; i < n; i++) c ^= (uint8_t)s[i];
  return c;
}

/**
 * Builds "<body>*XX\n".
 * @param body Line content without checksum.
 * @param out Output buffer.
 * @param cap Size of out.
 * @return Length written (without NUL), or 0 if it does not fit.
 */
inline size_t frame(const char* body, char* out, size_t cap) {
  const size_t n = strlen(body);
  if (n + 5 > cap) return 0;  // "*XX\n" + NUL
  memcpy(out, body, n);
  snprintf(out + n, cap - n, "*%02X\n", xorSum(body, n));
  return n + 4;
}

/**
 * Verifies and strips the "*XX" checksum (and a trailing CR) in place.
 * @param line NUL-terminated line without the '\n'.
 * @return true when the checksum is present and matches.
 */
inline bool unframe(char* line) {
  size_t n = strlen(line);
  if (n && line[n - 1] == '\r') line[--n] = '\0';
  if (n < 4 || line[n - 3] != '*') return false;
  char* end = nullptr;
  const unsigned long want = strtoul(line + n - 2, &end, 16);
  if (end != line + n) return false;
  line[n - 3] = '\0';
  return xorSum(line, n - 3) == (uint8_t)want;
}

/**
 * Splits a line at commas in place, keeping empty fields (unlike strtok).
 * @param line Line to split (modified: commas become NUL).
 * @param fields Receives pointers to each field.
 * @param maxFields Capacity of fields.
 * @return Number of fields (at least 1).
 */
inline uint8_t split(char* line, char** fields, uint8_t maxFields) {
  uint8_t count = 0;
  char* p = line;
  while (count < maxFields) {
    fields[count++] = p;
    char* comma = strchr(p, ',');
    if (!comma) break;
    *comma = '\0';
    p = comma + 1;
  }
  return count;
}

/**
 * Whether a field is a plain decimal number (optional sign, digits, optional fraction).
 * @param s Field text.
 * @return true for e.g. "1.234", "-0.5", "346"; false for "", "nan", "1e5", "1.2.3".
 */
inline bool isNumber(const char* s) {
  if (*s == '-' || *s == '+') s++;
  bool digits = false, dot = false;
  for (; *s; s++) {
    if (*s >= '0' && *s <= '9') digits = true;
    else if (*s == '.' && !dot) dot = true;
    else return false;
  }
  return digits;
}

/**
 * Whether a field is a safe upper-case word for a JSON string (A-Z, 0-9, _).
 * @param s Field text.
 * @return true for e.g. "IDLE", "LOCAL_MODE"; false for "" or anything with quotes / spaces.
 */
inline bool isWord(const char* s) {
  if (!*s) return false;
  for (; *s; s++) {
    if (!((*s >= 'A' && *s <= 'Z') || (*s >= '0' && *s <= '9') || *s == '_')) return false;
  }
  return true;
}

/** Appends text to a JSON buffer; tracks overflow. */
struct JsonOut {
  char* buf;
  size_t cap;
  size_t len;
  bool ok;

  /**
   * Starts an empty buffer.
   * @param b Output buffer.
   * @param c Its capacity.
   */
  JsonOut(char* b, size_t c) : buf(b), cap(c), len(0), ok(c > 0) {
    if (ok) buf[0] = '\0';
  }

  /**
   * Appends raw text.
   * @param s Text to append.
   * @return Nothing; ok becomes false if it does not fit.
   */
  void raw(const char* s) {
    const size_t n = strlen(s);
    if (!ok || len + n + 1 > cap) { ok = false; return; }
    memcpy(buf + len, s, n + 1);
    len += n;
  }

  /**
   * Appends "key":value where value is a number field or null.
   * @param key JSON key (with leading comma handled by the caller).
   * @param field Field text; empty or invalid -> null.
   */
  void number(const char* key, const char* field) {
    raw("\""); raw(key); raw("\":");
    raw(isNumber(field) ? field : "null");
  }

  /**
   * Appends "key":true/false from a "1"/"0" field.
   * @param key JSON key.
   * @param field Field text ("1" = true).
   */
  void boolean(const char* key, const char* field) {
    raw("\""); raw(key); raw("\":");
    raw(strcmp(field, "1") == 0 ? "true" : "false");
  }

  /**
   * Appends "key":"WORD", or "key":null if the field is not a safe word.
   * @param key JSON key.
   * @param field Field text.
   */
  void word(const char* key, const char* field) {
    raw("\""); raw(key); raw("\":");
    if (isWord(field)) { raw("\""); raw(field); raw("\""); }
    else raw("null");
  }
};

/**
 * Converts the fields of an L line to the crane/live JSON.
 * @param f Fields (f[0] == "L").
 * @param n Field count (must be 12).
 * @param out Output buffer.
 * @param cap Its capacity.
 * @return true when the JSON was written.
 */
inline bool liveJson(char** f, uint8_t n, char* out, size_t cap) {
  if (n != 12 || strcmp(f[0], "L") != 0 || !isNumber(f[2]) || !isWord(f[7])) return false;
  JsonOut j(out, cap);
  j.raw("{"); j.number("t", f[1]);
  j.raw(","); j.number("kg", f[2]);
  j.raw(","); j.number("max", f[3]);
  j.raw(","); j.number("h", f[4]);
  j.raw(","); j.number("a", f[5]);
  j.raw(","); j.boolean("top", f[6]);
  j.raw(","); j.word("st", f[7]);
  j.raw(","); j.word("mode", f[8]);
  j.raw(","); j.word("src", f[9]);
  j.raw(","); j.number("us", f[10]);
  j.raw(","); j.boolean("obs", f[11]);
  j.raw("}");
  return j.ok;
}

/**
 * Converts the fields of an A line to the crane/ack JSON.
 * @param f Fields (f[0] == "A"): id, ok (1/0), reason (may be empty).
 * @param n Field count (must be 4).
 * @param out Output buffer.
 * @param cap Its capacity.
 * @return true when the JSON was written.
 */
inline bool ackJson(char** f, uint8_t n, char* out, size_t cap) {
  if (n != 4 || strcmp(f[0], "A") != 0 || !isNumber(f[1])) return false;
  JsonOut j(out, cap);
  j.raw("{"); j.number("id", f[1]);
  j.raw(","); j.boolean("ok", f[2]);
  if (isWord(f[3])) { j.raw(","); j.word("reason", f[3]); }
  j.raw("}");
  return j.ok;
}

/**
 * Converts the fields of an E line to the crane/events JSON.
 * @param f Fields (f[0] == "E"): t, type, kg (may be empty).
 * @param n Field count (must be 4).
 * @param out Output buffer.
 * @param cap Its capacity.
 * @return true when the JSON was written.
 */
inline bool eventJson(char** f, uint8_t n, char* out, size_t cap) {
  if (n != 4 || strcmp(f[0], "E") != 0 || !isWord(f[2])) return false;
  JsonOut j(out, cap);
  j.raw("{"); j.number("t", f[1]);
  j.raw(","); j.word("type", f[2]);
  j.raw(","); j.number("kg", f[3]);
  j.raw("}");
  return j.ok;
}

/**
 * Builds the retained crane/status JSON.
 * @param online Whether the crane (Uno) is talking.
 * @param fw Firmware tag, e.g. "m2.0".
 * @param sensors Space-separated fitted sensors from the S line ("" = unknown, key omitted).
 * @param out Output buffer.
 * @param cap Its capacity.
 * @return true when the JSON was written.
 */
inline bool statusJson(bool online, const char* fw, const char* sensors, char* out, size_t cap) {
  JsonOut j(out, cap);
  j.raw(online ? "{\"online\":true" : "{\"online\":false");
  j.raw(",\"fw\":\""); j.raw(fw); j.raw("\"");
  if (*sensors) {
    j.raw(",\"sensors\":[");
    char name[12];
    const char* p = sensors;
    bool first = true;
    while (*p) {
      while (*p == ' ') p++;
      size_t k = 0;
      while (*p && *p != ' ' && k < sizeof name - 1) {
        const char c = *p++;
        if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')) name[k++] = c;  // only safe chars
      }
      while (*p && *p != ' ') p++;  // skip the rest of an over-long name
      name[k] = '\0';
      if (k) {
        if (!first) j.raw(",");
        j.raw("\""); j.raw(name); j.raw("\"");
        first = false;
      }
    }
    j.raw("]");
  }
  j.raw("}");
  return j.ok;
}

/**
 * Builds the C line body for an app command, after checking the command name.
 * @param id Command id from the app.
 * @param cmd Command name (LIFT, LOWER, GOTO, STOP, RESET, TARE, SET_MAX, PING).
 * @param hasValue Whether the JSON had a numeric "value".
 * @param value The value (GOTO mm, SET_MAX kg).
 * @param out Output buffer for the body (no checksum).
 * @param cap Its capacity.
 * @return true for a known command (an unknown one is dropped, the Uno never sees it).
 */
inline bool commandBody(long id, const char* cmd, bool hasValue, double value, char* out, size_t cap) {
  static const char* const known[] = {"LIFT", "LOWER", "GOTO", "STOP", "RESET", "TARE", "SET_MAX", "PING"};
  bool ok = false;
  for (const char* k : known) ok = ok || strcmp(cmd, k) == 0;
  if (!ok || id < 0 || id > 65535) return false;
  const int n = hasValue ? snprintf(out, cap, "C,%ld,%s,%.3f", id, cmd, value) : snprintf(out, cap, "C,%ld,%s", id, cmd);
  return n > 0 && (size_t)n < cap;
}

}  // namespace crane_link
