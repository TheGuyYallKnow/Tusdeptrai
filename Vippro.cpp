int E1_Increments[4] = {29,45,75,149};

// Kiem tra va dieu chinh gia tri EXP neu no vuot qua hoac duoi gioi han
void ClampEXP(int &EXP)
{
    // std::clamp(EXP, 0, 600); // Perfect we got no clamp :>
    if (EXP > 600) {
        EXP = 600;
    } else if (EXP < 0) {
        EXP = 0;
    }
}

// Kiem tra va dieu chinh gia tri HP neu no vuot qua hoac duoi gioi han
void ClampHP(int &HP)
{
    if (HP > 666) {
        HP = 666;
    } else if (HP < 0) {
        HP = 0;
    }
}

// Kiem tra va dieu chinh gia tri M neu no vuot qua hoac duoi gioi han
void ClampM(int &M)
{
    if (M > 3000) {
        M = 3000;
    } else if (M < 0) {
        M = 0;
    }
}

// Task 1
int firstMeet(int & exp1, int & exp2, int E1)
