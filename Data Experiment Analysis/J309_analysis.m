%sample: Hans, a BSCCO cuprate 20-30nm thick 2-terminal

    G=2.402241451520955e-02;
    Ti=5.505100644728684e+01;
    Tn=7.729805599694356e+01;
    T_DUT= @(P_meas, R) (P_meas*2/G-((R-50)/(R+50))^2*Ti-Tn)/(1-((R-50)/(R+50))^2);
    dT_DUT= @(P_meas, R) (P_meas*2/G)/(1-((R-50)/(R+50))^2);

    Iac_approx=J309.Iac;
    
    %plot the raw data
    figure(1);
    clf;
    subplot(2,2,1);
    hold on;
    for(i=1:length(J309.Tset))
       h=plot(J309.Vdc,J309.R(i,:),'.-','DisplayName',sprintf('%g K',J309.Tset(i)));
    end
    xlabel('Vdc (V)');
    ylabel('Rac (ohms)');
    title('J309');
    l = legend('show','Location','best');
    
    subplot(2,2,2);
    hold on;
    for(i=1:length(J309.Tset))
        plot(J309.Vdc,J309.VNdc(i,:),'.-');
    end
    xlabel('Vdc (V)');
    ylabel('Vndc (V)');
    title('J309');
    
    subplot(2,2,3);
    hold on;
    for(i=1:length(J309.Tset))
        plot(J309.Vdc,J309.VNac_X(i,:),'.-');
    end
    xlabel('Vdc (V)');
    ylabel('Vnac_X (V)');
    title('J309');
    subplot(2,2,4);
    hold on;
    for(i=1:length(J309.Tset))
        plot(J309.Vdc,J309.VNac2f_X(i,:),'.-');
    end
    xlabel('Vdc (V)');
    ylabel('Vnac2f_X (V)');
    title('J309');
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %plot the data vs the approximate current
    figure(2);
    clf;
    subplot(2,2,1);
    hold on;
    for(i=1:length(J309.Tset))
       h=plot(J309.Vdc/J309.Rex_dc,J309.R(i,:),'.-','DisplayName',sprintf('%g K',J309.Tset(i)));
    end
    xlabel('Idc (A)');
    ylabel('Rac (ohms)');
    title('J309');
    l = legend('show','Location','best');
    
    subplot(2,2,2);
    hold on;
    for(i=1:length(J309.Tset))
        plot(J309.Vdc/J309.Rex_dc,J309.VNdc(i,:),'.-');
    end
    xlabel('Idc (A)');
    ylabel('Vndc (V)');
    title('J309');
    
    subplot(2,2,3);
    hold on;
    for(i=1:length(J309.Tset))
        plot(J309.Vdc/J309.Rex_dc,J309.VNac_X(i,:),'.-');
    end
    xlabel('Idc (A)');
    ylabel('Vnac_X (V)');
    title('J309');
    subplot(2,2,4);
    hold on;
    for(i=1:length(J309.Tset))
        plot(J309.Vdc/J309.Rex_dc,J309.VNac2f_X(i,:),'.-');
    end
    xlabel('Idc (A)');
    ylabel('Vnac2f_X (V)');
    title('J309');
    
    
    %we need to "integrate" the ac resistance to get the dc resistance
    
    %convert the noise to effective noise temperature
    figure(3);
    clf;
    subplot(2,2,1);
    hold on;
    for(i=1:length(J309.Tset))
        plot(J309.Vdc,arrayfun(T_DUT,J309.VNdc(i,:),J309.R(i,:)),'.-');
    end
    xlabel('Vdc (V)');
    ylabel('DC Noise Power (K)');
    title('J309');
    subplot(2,2,2);
    hold on;
    for(i=1:length(J309.Tset))
        plot(J309.Vdc,arrayfun(T_DUT,J309.VNdc(i,:),J309.R(i,:))-J309.Tset(i),'.-');
    end
    xlabel('Vdc (V)');
    ylabel('DC Noise Power - T_{bath} (K)');
    title('J309');
        subplot(2,2,3);
    hold on;
    for(i=1:length(J309.Tset))
        plot(J309.Vdc,arrayfun(T_DUT,J309.VNdc(i,:),J309.R(i,:))-T_DUT(J309.VNdc(i,21),J309.R(i,21)),'.-');
    end
    xlabel('Vdc (V)');
    ylabel('DC Noise Power - T_{bath} (K)');
    title('J309');
    grid on;
    
    
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %convert the noise to effective noise temperature
    figure(4);
    clf;
    subplot(2,2,1);
    hold on;
    for(i=1:length(J309.Tset))
        plot(J309.Vdc/J309.Rex_dc,arrayfun(T_DUT,J309.VNdc(i,:),J309.R(i,:)),'.-');
    end
    xlabel('Idc (A)');
    ylabel('DC Noise Power (K)');
    title('J309');
    subplot(2,2,2);
    hold on;
    for(i=1:length(J309.Tset))
        plot(J309.Vdc/J309.Rex_dc,arrayfun(T_DUT,J309.VNdc(i,:),J309.R(i,:))-J309.Tset(i),'.-');
    end
    xlabel('Idc (A)');
    ylabel('DC Noise Power - T_{bath} (K)');
    title('J309');
        subplot(2,2,3);
    hold on;
    for(i=1:length(J309.Tset))
        plot(J309.Vdc/J309.Rex_dc,arrayfun(T_DUT,J309.VNdc(i,:),J309.R(i,:))-T_DUT(J309.VNdc(i,21),J309.R(i,21)),'.-');
    end
    xlabel('Idc (A)');
    ylabel('DC Noise Power - T_{bath} (K)');
    title('J309');
    grid on;

    
    figure(6)
    clf;
    %integrate diff resistance to get resistance
    for(i=1:length(J309.Tset))
        xdata=J309.Vdc/J309.Rex_dc;
        ydata=J309.R(i,:);
        p=polyfit(xdata,ydata,12);
        for(j=1:length(J309.Idc))
            pint=polyint(p);
            I0=J309.Idc(j);
            V0=polyval(pint,I0)-polyval(pint,0);
            R(i,j)=V0/I0;
            if(j==21)
                R(i,j)=J309.R(i,j); %this is the resistance, not the differential resistance
            end
        end
        plot(J309.Idc,R(i,:));
        hold on;
    end
    xlabel('Idc (A)');
    ylabel('R = V/I (Ohms)');
    
    
    
    k_B=1.38064852e-23;
    e=1.60217662e-19;
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure(5);
    clf;
    subplot(2,2,1);
    hold on;
    %S_watts=F2e Iac * Rac
    %v_meas=G*T=G0*4kT = G0 S_JW = G/(4k) *S_JW
    %v_meas=G/(4k) * S_W=G/(4k)*F2e Iac Rac
    
    %F= vmeas *4k /(G2e Iac Rac)
    for(i=1:length(J309.Tset))
        %arrayfun(dT_DUT,J309.VNac_X(i,:),J309.R(i,:)) gives us the change in device power -- in units of kelvin
        %arrayfun(dT_DUT,J309.VNac_X(i,:),J309.R(i,:))/Iac gives us the change in device power -- kelvin/amp
        %arrayfun(dT_DUT,J309.VNac_X(i,:),J309.R(i,:))/Iac*k_B*4 --joule / amp
        %arrayfun(dT_DUT,J309.VNac_X(i,:),J309.R(i,:))/Iac*k_B*4/(2e) -- joule/(amp*coulomb) = volts/amp
        %arrayfun(dT_DUT,J309.VNac_X(i,:),J309.R(i,:))/Iac*k_B*4/(2e)/Rac -- volts/(amp*ohm) = volts/volt = unitless
        plot(J309.Vdc/J309.Rex_dc,arrayfun(dT_DUT,J309.VNac_X(i,:),J309.R(i,:))/Iac_approx,'.-');
    end
    xlabel('Idc (A)');
    ylabel('AC Noise Power (K/A)');
    title('J309');
    
    subplot(2,2,2);
    hold on;
    for(i=1:length(J309.Tset))
        plot(J309.Vdc/J309.Rex_dc.*R(i,:),arrayfun(dT_DUT,J309.VNac_X(i,:),J309.R(i,:))/Iac_approx./J309.R(i,:),'.-');
    end
    xlabel('Vds dc (V)');
    ylabel('AC Noise Power (K/Vds)');
    title('J309');
    
    subplot(2,2,3);
    hold on;
    for(i=1:length(J309.Tset))
        plot(J309.Vdc/J309.Rex_dc.*R(i,:),arrayfun(dT_DUT,J309.VNac_X(i,:),J309.R(i,:))/Iac_approx./J309.R(i,:)*4*k_B/(2*e),'.-');
    end
    xlabel('Vds dc (V)');
    ylabel('Fano Factor');
    title('J309');
    
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure(7);
    clf;
    hold on;
    for(i=1:length(J309.Tset))
        plot(J309.Vdc/J309.Rex_dc.*R(i,:)*e/(J309.Tset(i)*k_B),arrayfun(dT_DUT,J309.VNac_X(i,:),J309.R(i,:))/Iac_approx./J309.R(i,:)*4*k_B/(2*e),'.-');
    end
    xlabel('Vds dc (eV_{dsdc}/(k_BT))');
    ylabel('Fano Factor');
    title('J309');
    
    
    %%%%% Computer G_thermal %%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %G_th = (Irms)^2 R / (sqrt(2) * Trms)
    
    
