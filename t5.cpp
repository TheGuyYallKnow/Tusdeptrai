int findCorrectPassword(const char * arr_pwds[], int num_pwds)
{
    // SMH Arrays in c++ is too sad
  map<string, int> count; // Should be List in python, Table in Lua
  for (int i = 0; i < num_pwds; i++) {
    count[arr_pwds[i]]++;
  }

  // Tìm mật khẩu có số lần xuất hiện cao nhất
  string mostFrequentPassword = "";
  int maxCount = 0;
  for (auto it = count.begin(); it != count.end(); it++) {
    if (it->second > maxCount) {
      maxCount = it->second;
      mostFrequentPassword = it->first;
    }
  }

  // Tìm vị trí đầu tiên của mật khẩu xuất hiện nhiều nhất
  int firstOccurence = -1;
  for (int i = 0; i < num_pwds; i++) {
    if (arr_pwds[i] == mostFrequentPassword) {
      firstOccurence = i;
      break;
    }
  }

  // Kiểm tra xem có mật khẩu nào có số lần xuất hiện cao nhất và độ dài dài nhất hay không
  for (auto it = count.begin(); it != count.end(); it++) {
    if (it->second == maxCount && it->first.length() > mostFrequentPassword.length()) {
      mostFrequentPassword = it->first;
      firstOccurence = -1;
      break;
    }
  }

  // Tìm vị trí đầu tiên của mật khẩu có số lần xuất hiện cao nhất và độ dài dài nhất
  for (int i = 0; i < num_pwds; i++) {
    if (arr_pwds[i] == mostFrequentPassword) {
      firstOccurence = i;
      break;
    }
  }

    return firstOccurence; // Return -1 if no correct password found
}
