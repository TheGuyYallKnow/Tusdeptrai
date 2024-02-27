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
{
    //TODO: implement task
    if (E1 >= 0 && E1 <= 3) {
        exp2 += E1_Increments [E1];
        float D = E1 * 3 + exp1 * 7;
        int PseudoD = static_cast<int>(ceil(D));
        float PseudoExp1 = static_cast<float>(exp1);
        if (PseudoD % 2 == 1) {
            PseudoExp1 -= D/100;
        } else {
            PseudoExp1 += D/200;
        }
        exp1 = static_cast<int>(ceil(PseudoExp1));
        ClampEXP(exp1);
        ClampEXP(exp2);
    } else if (E1 > 3 && E1 <= 99) {
        float PseudoExp1 = static_cast<float>(exp1);
        float PseudoExp2 = static_cast<float>(exp2);
        float PseudoE1 = static_cast<float>(E1);

        struct Explanation { // Bruh cpp so weid?
            static void NumberOne(float & exp2, float E1)
            {
                exp2 += (E1/4 + 19);
                exp2 = ceil(exp2);
            };
            static void NumberTwo(float & exp2, float E1) // bruh they are in the same stack wth?
            {
                exp2 += (E1/9 + 21);
                exp2 = ceil(exp2);
            };
            static void NumberThree(float & exp2, float E1)
            {
                exp2 += (E1/16 + 17);
                exp2 = ceil(exp2);
            };
        };

        if (E1 >= 4 && E1 <= 19) {
            Explanation::NumberOne(PseudoExp2, PseudoE1);
        } else if (E1 >= 20 && E1 <= 49) {
            Explanation::NumberTwo(PseudoExp2, PseudoE1);
        } else if (E1 >= 50 && E1 <= 65) {
            Explanation::NumberThree(PseudoExp2, PseudoE1);
        } else if (E1 >= 66 && E1 <= 79) {
            Explanation::NumberOne(PseudoExp2, PseudoE1);
            if (PseudoExp2 > 200) {
                Explanation::NumberTwo(PseudoExp2, PseudoE1);
            }
        } else if (E1 >= 80 && E1 <= 99) {
            Explanation::NumberOne(PseudoExp2, PseudoE1);
            Explanation::NumberTwo(PseudoExp2, PseudoE1);
             if (PseudoExp2 > 400) {
                Explanation::NumberThree(PseudoExp2, PseudoE1);
            }
        }

        exp1 = static_cast<int>(ceil(PseudoExp1 - E1));
        exp2 = static_cast<int>(PseudoExp2);
        ClampEXP(exp1);
        ClampEXP(exp2);
    } else {
        // Out of range hoho
        return -99;
    }

    return exp1 + exp2;
}
