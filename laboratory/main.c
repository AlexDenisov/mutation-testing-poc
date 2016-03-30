extern int sum(int a, int b);

int test_main() {
  int result = sum(3, 5);
  int result_matches = result == 8;

  return result_matches;
}

