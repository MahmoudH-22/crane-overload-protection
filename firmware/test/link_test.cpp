/**
 * @file link_test.cpp
 * @brief Host unit tests for crane_link.h (the Uno <-> NodeMCU serial protocol).
 *
 * Build and run from the repo root:
 *   g++ -std=c++17 -Wall -Wextra -I firmware/uno/crane_uno_m2 firmware/test/link_test.cpp -o link_test && ./link_test
 */
#include <cstdio>
#include <cstring>
#include <string>

#include "crane_link.h"

using namespace crane_link;

static int failures = 0;

/**
 * Records a failed check.
 * @param ok Condition.
 * @param what Description printed on failure.
 * @param line Source line.
 */
static void check(bool ok, const char* what, int line) {
  if (!ok) {
    std::printf("FAIL line %d: %s\n", line, what);
    failures++;
  }
}
#define CHECK(x) check((x), #x, __LINE__)
#define CHECK_STR(a, b) check(std::string(a) == std::string(b), (std::string(a) + " == " + b).c_str(), __LINE__)

/**
 * Frames a body, then unframes and splits it like the receiver does.
 * @param body Line body.
 * @param buf Work buffer (receives the split fields).
 * @param fields Field pointers.
 * @return Field count, or 0 if the round trip failed.
 */
static uint8_t roundTrip(const char* body, char* buf, char** fields) {
  char framed[MAX_LINE];
  if (!frame(body, framed, sizeof framed)) return 0;
  framed[strlen(framed) - 1] = '\0';  // receiver strips '\n'
  std::strcpy(buf, framed);
  if (!unframe(buf)) return 0;
  return split(buf, fields, MAX_FIELDS);
}

int main() {
  char buf[MAX_LINE];
  char out[256];
  char* f[MAX_FIELDS];

  // --- framing
  {
    char framed[MAX_LINE];
    CHECK(frame("C,17,LIFT", framed, sizeof framed) == 13);
    CHECK(framed[std::strlen(framed) - 1] == '\n');
    // checksum of "H" is 0x48
    frame("H", framed, sizeof framed);
    CHECK_STR(framed, "H*48\n");
    char tiny[6];
    CHECK(frame("ABCDEF", tiny, sizeof tiny) == 0);
  }
  {
    char line[] = "H*48";
    CHECK(unframe(line));
    CHECK_STR(line, "H");
    char crlf[] = "H*48\r";
    CHECK(unframe(crlf));
    char bad[] = "H*49";
    CHECK(!unframe(bad));
    char noStar[] = "HELLO";
    CHECK(!unframe(noStar));
    char junk[] = "H*4Z";
    CHECK(!unframe(junk));
    char shortLine[] = "*00";
    CHECK(!unframe(shortLine));
  }

  // --- split keeps empty fields
  {
    char line[] = "L,1,,3,,";
    uint8_t n = split(line, f, MAX_FIELDS);
    CHECK(n == 6);
    CHECK_STR(f[1], "1");
    CHECK_STR(f[2], "");
    CHECK_STR(f[5], "");
  }

  // --- numbers / words
  CHECK(isNumber("1.234") && isNumber("-0.5") && isNumber("346") && isNumber("+2"));
  CHECK(!isNumber("") && !isNumber("-") && !isNumber("nan") && !isNumber("1e5") && !isNumber("1.2.3") && !isNumber("."));
  CHECK(isWord("IDLE") && isWord("LOCAL_MODE") && isWord("A1"));
  CHECK(!isWord("") && !isWord("idle") && !isWord("A\"B") && !isWord("A B"));

  // --- live: the two-sensor case (load cell + IR only)
  {
    uint8_t n = roundTrip("L,123456,1.234,1.500,,,1,TOP,REMOTE,NONE,,0", buf, f);
    CHECK(n == 12);
    CHECK(liveJson(f, n, out, sizeof out));
    CHECK_STR(out,
              "{\"t\":123456,\"kg\":1.234,\"max\":1.500,\"h\":null,\"a\":null,\"top\":true,\"st\":\"TOP\","
              "\"mode\":\"REMOTE\",\"src\":\"NONE\",\"us\":null,\"obs\":false}");
  }
  // --- live: every sensor present
  {
    uint8_t n = roundTrip("L,1,0.512,1.200,212.5,0.42,0,LIFTING,REMOTE,APP,180.0,1", buf, f);
    CHECK(liveJson(f, n, out, sizeof out));
    CHECK_STR(out,
              "{\"t\":1,\"kg\":0.512,\"max\":1.200,\"h\":212.5,\"a\":0.42,\"top\":false,\"st\":\"LIFTING\","
              "\"mode\":\"REMOTE\",\"src\":\"APP\",\"us\":180.0,\"obs\":true}");
  }
  // --- live: rejects bad lines
  {
    char a[] = "L,1,abc,1.5,,,0,IDLE,REMOTE,NONE,,0";
    uint8_t n = split(a, f, MAX_FIELDS);
    CHECK(!liveJson(f, n, out, sizeof out));  // weight must be a number
    char b[] = "L,1,0.5,1.5";
    n = split(b, f, MAX_FIELDS);
    CHECK(!liveJson(f, n, out, sizeof out));  // too few fields
    char c[] = "L,1,0.5,1.5,,,0,id\"le,REMOTE,NONE,,0";
    n = split(c, f, MAX_FIELDS);
    CHECK(!liveJson(f, n, out, sizeof out));  // state must be a safe word (no JSON injection)
    char d[] = "L,1,0.5,1.5,,,0,IDLE,REMOTE,NONE,,0";
    n = split(d, f, MAX_FIELDS);
    char small[40];
    CHECK(!liveJson(f, n, small, sizeof small));  // does not overflow a small buffer
  }

  // --- ack
  {
    uint8_t n = roundTrip("A,17,0,OVERLOAD", buf, f);
    CHECK(ackJson(f, n, out, sizeof out));
    CHECK_STR(out, "{\"id\":17,\"ok\":false,\"reason\":\"OVERLOAD\"}");
    n = roundTrip("A,20,1,", buf, f);
    CHECK(ackJson(f, n, out, sizeof out));
    CHECK_STR(out, "{\"id\":20,\"ok\":true}");
  }

  // --- event
  {
    uint8_t n = roundTrip("E,123999,OVERLOAD,1.530", buf, f);
    CHECK(eventJson(f, n, out, sizeof out));
    CHECK_STR(out, "{\"t\":123999,\"type\":\"OVERLOAD\",\"kg\":1.530}");
    n = roundTrip("E,5,TOP,", buf, f);
    CHECK(eventJson(f, n, out, sizeof out));
    CHECK_STR(out, "{\"t\":5,\"type\":\"TOP\",\"kg\":null}");
  }

  // --- status
  CHECK(statusJson(true, "m2.0", "kg top", out, sizeof out));
  CHECK_STR(out, "{\"online\":true,\"fw\":\"m2.0\",\"sensors\":[\"kg\",\"top\"]}");
  CHECK(statusJson(false, "m2.0", "", out, sizeof out));
  CHECK_STR(out, "{\"online\":false,\"fw\":\"m2.0\"}");
  CHECK(statusJson(true, "m2.0", "  kg  \"x top ", out, sizeof out));
  CHECK_STR(out, "{\"online\":true,\"fw\":\"m2.0\",\"sensors\":[\"kg\",\"x\",\"top\"]}");

  // --- commands
  {
    char body[48];
    CHECK(commandBody(17, "LIFT", false, 0, body, sizeof body));
    CHECK_STR(body, "C,17,LIFT");
    CHECK(commandBody(22, "SET_MAX", true, 1.2, body, sizeof body));
    CHECK_STR(body, "C,22,SET_MAX,1.200");
    CHECK(commandBody(5, "GOTO", true, 200, body, sizeof body));
    CHECK_STR(body, "C,5,GOTO,200.000");
    CHECK(!commandBody(1, "SELF_DESTRUCT", false, 0, body, sizeof body));
    CHECK(!commandBody(70000, "STOP", false, 0, body, sizeof body));
    // and the Uno can read it back
    uint8_t n = roundTrip("C,22,SET_MAX,1.200", buf, f);
    CHECK(n == 4);
    CHECK(std::atol(f[1]) == 22);
    CHECK_STR(f[2], "SET_MAX");
  }

  if (failures) {
    std::printf("%d check(s) failed\n", failures);
    return 1;
  }
  std::printf("All crane_link tests passed\n");
  return 0;
}
