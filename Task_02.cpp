// Task 2
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

float closestSquare(float value) {
    float minValue = floor(sqrt(value));
    float maxValue = ceil(sqrt(value));
    float closestValue = abs(sqrt(value) - minValue) < abs(sqrt(value) - maxValue) ? minValue : maxValue;
    float closestValue_02 = abs(sqrt(value) - minValue) < abs(sqrt(value) - maxValue) ? maxValue : minValue;

    if (closestValue_02 < closestValue) {
        return closestValue_02 * closestValue_02;
    }

    return closestValue * closestValue;
}

bool EvenChecker(float & CurrentMoney, int E) {
    if (E%2 == 1) {return true;}
    if (CurrentMoney < 0) {
        return false;
    }
    return true;
}

bool OddChecker(float & CurrentMoney, int E, float EstimatedMoney) {
    if (E%2 == 0) {return true;}
    if (CurrentMoney < EstimatedMoney) {
        return false;
    }
    return true;
}

void Ceil(float & exp, float & hp, float & M){
    hp = ceil(hp);
    exp = ceil(exp);
    M = ceil(M);
}

void Path_02(float & exp, float & hp, float & M,int E, float EstimatedM) {
    if (hp < 200) {
        hp *= 1.3;
        M -= 150;
    } else {
        hp *= 1.1;
        M -= 70;
    }
    Ceil(exp, hp, M);
    if (EvenChecker(M,E) == false) {
        return;
    }
    if (OddChecker(M,E,EstimatedM) == false) {
        return;
    }

    if (exp < 400) {
        M -= 200;
    } else {
        M -= 120;
    }
    exp *= 1.13;
    Ceil(exp, hp, M);
    if (EvenChecker(M,E) == false) {
        return;
    }
    if (OddChecker(M,E,EstimatedM) == false) {
        return;
    }

    if (exp < 300) {
        M -= 100;
    } else {
        M -= 120;
    }
    exp *= 0.9;
    Ceil(exp, hp, M);
    if (EvenChecker(M,E) == false) {
        return;
    }
    Ceil(exp,hp,M);
    if (OddChecker(M,E,EstimatedM) == false) {
        return;
    } else {
        if (E%2 == 1) {
            return Path_02(exp, hp, M, E, EstimatedM);
        }
    }
}

int traceLuggage(int & HP1, int & EXP1, int & M1, int E2)
{
    float CS_Exp1 = closestSquare(EXP1);
    float Exp1_Road = static_cast<float>(EXP1); // Chuyển từ int sang float để phòng mấy trường hợp đề cho phép tính ra số float...
    float HP1_Road = static_cast<float>(HP1);
    float M1_Road = static_cast<float>(M1);

    // Road_01:
    float P1 = ((Exp1_Road/CS_Exp1) + 80)/123;
    // HAHAHA
    if (Exp1_Road >= CS_Exp1) {
        P1 = 1;
    }

    // Road_02
    Path_02(Exp1_Road, HP1_Road, M1_Road, E2, M1_Road/2); // Bro is yelding LOL
    HP1_Road *= (1-0.17);
    Exp1_Road *= (1+0.17);
    Ceil(Exp1_Road, HP1_Road, M1_Road);
    float P2 = ((Exp1_Road/CS_Exp1) + 80)/123;
    if (Exp1_Road >= CS_Exp1) {
        P2 = 1;
    }

   // Road_03
   float P[] = {0.32, 0.47, 0.28, 0.79, 1, 0.5, 0.22, 0.83, 0.64, 0.11};
   int P3InAShell = 0;
   if (E2 < 10) {
        P3InAShell = E2;
    } else if (E2 >= 10 && E2 <= 99) {
        int sum = (E2 / 10) + (E2 % 10);
        P3InAShell = sum % 10;
    }
    float P3 = P[P3InAShell];

    // Calculation
    if (P1 == 1 && P2 == 1 && P3 == 1) {
        Exp1_Road *= 0.75;
    } else {
        float P_Avg = (P1 + P2 + P3)/3;
        if (P_Avg < 0.5) {
            HP1_Road *= 0.85;
            Exp1_Road *= 1.15;
        } else {
            HP1_Road *= 0.9;
            Exp1_Road *= 1.2;
        }
    }

    EXP1 = static_cast<int>(ceil(Exp1_Road));
    HP1 = static_cast<int>(ceil(HP1_Road));
    M1 = static_cast<int>(ceil(M1_Road));
    ClampEXP(EXP1);
    ClampHP(HP1);
    ClampM(M1);
    return HP1 + EXP1 + M1;
}
a
