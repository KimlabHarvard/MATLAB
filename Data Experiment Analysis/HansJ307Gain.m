function T_DUT = HansJ307Gain(P_meas, R)
    G=2.402241451520955e-02;
    Ti=5.505100644728684e+01;
    Tn=7.729805599694356e+01;
    gamma=(R-50)/(R+50);
    T_DUT=(P_meas*2/G-gamma^2*Ti-Tn)/(1-gamma^2);
end

