// Task 4
int checkPassword(const char * s, const char * email)
{
    // cout << "\n" << "S = " << s << "\n"<< "Email = " << email;  
    //ReDefining
    string Pseudo_S(s);
    string Pseudo_Email(email);
    string se = Pseudo_Email.substr(0, Pseudo_Email.find('@'));

    if (Pseudo_S.length() <= 7) {
        return -1;
    } else if (Pseudo_S.length() >= 21) {
        return -2;
    }

    const string Allowed_Character = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%";
    for (size_t i = 0; i < Pseudo_S.length(); ++i) {
        if (Allowed_Character.find(Pseudo_S[i]) == string::npos) { 
            return static_cast<int>(i);
        }
    }
    
    if (Pseudo_S.find(se) != string::npos) {
        return -300 -static_cast<int>(Pseudo_S.find(se));
    }

    for (size_t i = 0; i < Pseudo_S.length() - 2; ++i) {
        if (Pseudo_S[i] == Pseudo_S[i + 1] && Pseudo_S[i] == Pseudo_S[i+2]) {
            return -400 - static_cast<int>(i);
        }
    }

    const string Prohibited = "@#%$!";
    bool HasSpecChar = false;
    for (char letter : Pseudo_S) {
        if (Prohibited.find(letter) == string::npos) {
            return -5;
        }
    }

    return -10;
}
