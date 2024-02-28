float closestPerfectSquare(float value) {
    float minValue = floor(sqrt(value));
    float maxValue = ceil(sqrt(value));
    float closestValue = abs(sqrt(value) - minValue) < abs(sqrt(value) - maxValue) ? minValue : maxValue;
    float closestValue_02 = abs(sqrt(value) - minValue) < abs(sqrt(value) - maxValue) ? maxValue : minValue;

    if (closestValue_02 < closestValue) {
        return closestValue_02 * closestValue_02;
    }

    return closestValue * closestValue;
}

int traceLuggage(int & HP1, int & EXP1, int & M1, int E2)
{
    // INITIAL, IDK WHAT UR GIVING
    ClampEXP(EXP1);
    ClampHP(HP1);
    ClampM(M1);
    
    float PFS_Exp1 = closestPerfectSquare(EXP1);
    float PseudoExp1_Road = static_cast<float>(EXP1);
    float PseudoHP1_Road = static_cast<float>(HP1);
    float PseudoM1_Road = static_cast<float>(M1);
    cout << "Current HP Before: " << PseudoHP1_Road << endl;

    // Road_01:
    float P1 = ((PseudoExp1_Road/PFS_Exp1) + 80)/123;
    // HAHAHA
    if (PseudoExp1_Road >= PFS_Exp1) {
        P1 = 1;
    }

    // Road_02
    struct Sherlock { // Bruh cpp so weid?
        static void Adventure(float & exp, float & hp, float & M,int E, float EstimatedM)
        {
            if (hp < 200) {
                hp *= 1.3;
                M -= 150;
            } else {
                hp *= 1.1;
                M -= 70;
            }
            Sherlock::Ceil(exp, hp, M);
            cout << "Current HP: " << hp << endl;
            if (Sherlock::MChecker_Even(M,E) == false) {
                return;
            }
            if (Sherlock::MChecker_Odd(M,E,EstimatedM) == false) {
                return;
            }

            if (exp < 400) {
                M -= 200;
            } else {
                M -= 120;
            }
            exp *= 1.13;
            Sherlock::Ceil(exp, hp, M);
            if (Sherlock::MChecker_Even(M,E) == false) {
                return;
            }
            if (Sherlock::MChecker_Odd(M,E,EstimatedM) == false) {
                return;
            }

            if (exp < 300) {
                M -= 100;
            } else {
                M -= 120;
            }
            exp *= 0.9;
            Sherlock::Ceil(exp, hp, M);
            if (Sherlock::MChecker_Even(M,E) == false) {
                return;
            }
            Sherlock::Ceil(exp,hp,M);
            if (Sherlock::MChecker_Odd(M,E,EstimatedM) == false) {
                return;
            } else {
                if (E%2 == 1) {
                    return Sherlock::Adventure(exp, hp, M, E, EstimatedM);
                }
            }
        };
        static bool MChecker_Even(float & CurrentMoney, int E) {
            if (E%2 == 1) {return true;}
            if (CurrentMoney < 0) {
                return false;
            }
            return true;
        }
        static bool MChecker_Odd(float & CurrentMoney, int E, float EstimatedMoney) {
            if (E%2 == 0) {return true;}
            if (CurrentMoney < EstimatedMoney) {
                return false;
            }
            return true;
        }
        static void Ceil(float & exp, float & hp, float & M){
            hp = ceil(hp);
            exp = ceil(exp);
            M = ceil(M);
        }
    };
    Sherlock::Adventure(PseudoExp1_Road, PseudoHP1_Road, PseudoM1_Road, E2, PseudoM1_Road/2); // Bro is yelding LOL
    PseudoHP1_Road *= (1-0.17);
    PseudoExp1_Road *= (1+0.17);
    cout << "Current HP After finished: " << PseudoHP1_Road << endl;
    Sherlock::Ceil(PseudoExp1_Road, PseudoHP1_Road, PseudoM1_Road);
    float P2 = ((PseudoExp1_Road/PFS_Exp1) + 80)/123;
    if (PseudoExp1_Road >= PFS_Exp1) {
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
    cout << "Got: " << E2 << ",Shell: " << P3InAShell << ",Found: " << P[P3InAShell] << " ";
    float P3 = P[P3InAShell];

    // Calculation
    if (P1 == 1 && P2 == 1 && P3 == 1) {
        PseudoExp1_Road *= 0.75;
    } else {
        float P_Avg = (P1 + P2 + P3)/3;
        if (P_Avg < 0.5) {
            PseudoHP1_Road *= 0.85;
            PseudoExp1_Road *= 1.15;
        } else {
            PseudoHP1_Road *= 0.9;
            PseudoExp1_Road *= 1.2;
        }
        cout << "\nAverageP: " << P_Avg;
    }

    cout << "\nP1:" << P1 << " P2:"<< P2 << " P3:" << P[P3InAShell];
    cout << "\n";

    EXP1 = static_cast<int>(ceil(PseudoExp1_Road));
    HP1 = static_cast<int>(ceil(PseudoHP1_Road));
    M1 = static_cast<int>(ceil(PseudoM1_Road));
    ClampEXP(EXP1);
    ClampHP(HP1);
    ClampM(M1);
    return HP1 + EXP1 + M1;
}
a
