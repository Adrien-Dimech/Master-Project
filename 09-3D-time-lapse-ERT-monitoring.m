%% ----------------- 3D-time-lapse-ERT-monitoring -------------------------
%
% Adrien Dimech - Master Project - 21/04/2018
%
% -------------------------------------------------------------------------
% Matlab codes to prepare - process - visualize and interpret 3D time-lapse 
% geolelectrical monitoring of a waste rock pile.
% -------------------------------------------------------------------------
%
% This Matlab code was designed to process inversion results (E4D) of the 
% 3D time-lapse geoelectrical monitoring of an experimental waste rock
% pile. Part I loads geoelectrical database from Excel files and
% pre-processes the measures. Files of data are created to be inversed with
% E4D (Johnson, 2010). Part II loads inversion files and post-processes the
% geophysical images of the waste rock pile over time in 3D. 1D, 2D, 3D
% and 4D images are generated from the inversion and geoelectrical data are
% compared to hydrogeophysical measurements.
%
% Feel free to visit : https://www.researchgate.net/profile/Adrien_Dimech
% for more information about my research or contact me for more information
% and data files : adrien.dimech@gmail.com
% 

%% ---------------------- I : AVANT INVERSION -----------------------------
for o=1
    %% I - 1 Chargement des données
    for o=1
        clear all
        figure
        p = get(gcf,'Position');
        set(0,'DefaultFigurePosition',p);
        close all
        load PRO_OPT_1000.mat
        T_CORR=0.21+1;
        
        %     C_sable=[255/255 192/255 0/255];
        %     C_anorthosite=[125/255 121/255 121/255];
        %     C_ilmenite=[59/255 56/255 56/255];
        
        C_sable=[255/255 230/255 153/255];
        C_anorthosite=[208/255 206/255 206/255];
        C_ilmenite=[127/255 127/255 127/255];
        
        
        % ARROSAGE DE LA HALDE
        load ARROSAGE.mat
        
        % ABEM imagerie
        FichierExcel = 'DATA.xlsx';
        [~,b]=xlsfinfo(FichierExcel);
        NbPages = length(b(1,:));
        
        % Enregistrement des donnees dans RAW_DATA
        for i=1:NbPages
            RAW_DATA{i} = xlsread(FichierExcel,i);
        end
        
        % DATA HYDRO
        FichierExcel_2 = 'TOTAL.xlsx';
        [~,b_2]=xlsfinfo(FichierExcel_2);
        NbPages_2 = length(b_2(1,:));
        
        % Enregistrement des donnees dans RAW_DATA
        for i=1
            RAW_DATA_HYDRO{i} = xlsread(FichierExcel_2,i);
            RAW_DATA_HYDRO{i}(:,1)=RAW_DATA_HYDRO{i}(:,1)-1;
        end
        
        for i=1:NbPages
            DATA1{i}=RAW_DATA{i}(:,Colonnes);
            DATA1{i}(:,1)=DATA1{i}(:,1)-T_CORR;
        end
        
        % Configuration focus
        CONFIG_FOCUS{1}=zeros(1,NbPages);
        CONFIG_TOT=zeros(1,4);
        count=0;
        for i=1:NbPages
            for j=1:length(DATA1{i}(:,1))
                C1=DATA1{i}(j,2);
                C2=DATA1{i}(j,3);
                P1=DATA1{i}(j,4);
                P2=DATA1{i}(j,5);
                trouve=find(C1==CONFIG_TOT(:,1)&C2==CONFIG_TOT(:,2)&P1==CONFIG_TOT(:,3)&P2==CONFIG_TOT(:,4));
                
                if isempty(trouve)
                    count=count+1;
                    trouve=count;
                    CONFIG_FOCUS{trouve}=zeros(1,10);
                    CONFIG_TOT(trouve,1:4)=[C1,C2,P1,P2];
                end
                
                CONFIG_FOCUS{trouve}(end+1,1:10)=DATA1{i}(j,:);
                % 9 = R
                % 10 = var R %
                
                % FACTEUR GEOMETRIQUE / RHO APP / VAR SUR RHO APP
                trouve_2=find(C1==PRO_OPT_1000(:,1)&C2==PRO_OPT_1000(:,2)&P1==PRO_OPT_1000(:,3)&P2==PRO_OPT_1000(:,4));
                if isempty(trouve_2)==0
                    % facteur géométrique
                    CONFIG_FOCUS{trouve}(end,11)=PRO_OPT_1000(trouve_2,5);
                    % Resistivité apparente
                    CONFIG_FOCUS{trouve}(end,12)=CONFIG_FOCUS{trouve}(end,9)*CONFIG_FOCUS{trouve}(end,11);
                    % Variation sur Rho App
                    CONFIG_FOCUS{trouve}(end,13)=CONFIG_FOCUS{trouve}(end,11)*CONFIG_FOCUS{trouve}(end,10);
                else
                    CONFIG_FOCUS{trouve}(end,11:13)=[0,0,0];
                end
                
            end
        end
        
        
        % suppression des premieres lignes vierges
        for i=1:length(CONFIG_FOCUS)
            CONFIG_FOCUS{1,i}(1,:)=[];
            CONFIG_FOCUS{1,i}(CONFIG_FOCUS{1,i}(:,6)==0,:)=[];
        end
        
        % Filtrage des valeurs uniques
        elimination=0;
        for i=1:length(CONFIG_FOCUS)
            if length(CONFIG_FOCUS{1,i}(:,1))<3
                elimination(end+1,1)=i;
            end
        end
        elimination(1,:)=[];
        elimination=sortrows(elimination,-1);
        
        for i=1:length(elimination(:,1))
            CONFIG_FOCUS(:,elimination(i,1))=[];
            CONFIG_TOT(elimination(i,1),:)=[];
        end
    end
    
    %% I - 2 Elec et maillage & Calcul sensibilité
    for o=1
        load COORD_ELEC_SORT.mat
        ELEC=COORD_ELEC_SORT;
        load Maillage3DSurface_2.mat
        ELEC_FAUSSES=[7;16;27;41;46;160;191];
        ELEC_MAUVAISES=[4;10;12;14;20;22;37;53;62;71];
        % Maillage
        for o=1
            dX = 1; %résolution spatiale en X
            dY = 1; %résolution spatiale en Y
            dZ = 0.5; %résolution spatiale en Z
            [X,Y,Z] = meshgrid(30:dX:95,21:dY:31,2:dZ:9);
            
            % Création points
            COORD=0;
            for i=1:length(X(1,:,1))
                for j=1:length(X(:,1,1))
                    for k=1:length(X(1,1,:))
                        COORD(end+1,1)=X(1,i,1);
                        COORD(end,2)=Y(j,1,1);
                        COORD(end,3)=Z(1,1,k);
                    end
                end
            end
            COORD(1,:)=[];
            
            pente=(5.665-7.563)/(91.07-56.74); % cf. FIGURE INTITULÉE PENTE_SURFACE
            
            
            COORD_2=0;
            for i=1:length(COORD(:,1))
                if COORD(i,3)<7.563+pente*(COORD(i,1)-56.74)
                    COORD_2(end+1,1:3)=COORD(i,1:3);
                end
            end
            MAILLAGE=COORD;
        end
        
        % Sensibilités duos
        for o=1
            % Matrice des duos possibles
            DUOS=zeros(192*191,2);
            count=0;
            tic
            for elec1=1:192
                for elec2=1:192
                    if elec1~=elec2
                        count=count+1;
                        % DUOS_AVANCEMENT=round(count/(192*191)*100);
                        DUOS(count,1:2)=[elec1,elec2];
                    end
                end
            end
            toc
            
            % (X-Xi)(X-Xj)+(Y-Yi)(Y-Yj)+(Z-Zi)(Z-Zj)
            clear Mat1
            Mat1=zeros(length(MAILLAGE(:,1)),length(DUOS(:,1)));
            tic
            for o=1:1
                for j=1:length(DUOS(:,1))
                    clear somme
                    somme=0;
                    for colonne=1:3
                        somme=somme+(MAILLAGE(:,colonne)-ELEC(DUOS(j,1),colonne)).*(MAILLAGE(:,colonne)-ELEC(DUOS(j,2),colonne));
                    end
                    Mat1(:,j)=somme;
                    % MAT1_AVANCEMENT=round(j/length(DUOS(:,1))*100)
                end
            end
            toc
            
            % ((X-Xi)^2+(Y-Yi)^2+(Z-Zi)^2)^1.5
            clear Mat2
            tic
            for j=1:length(ELEC(:,1))
                somme=0;
                for colonne=1:3
                    somme=somme+(MAILLAGE(:,colonne)-ELEC(j,colonne)).^2;
                end
                Mat2(:,j)=somme.^1.5;
            end
            toc
            
            % Matrice de sensibilité
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % REMARQUE OLA + ABDERREZAK : utiliser COMSOL avec modèle résistivités pour
            % prendre en compte hétérogénéité du modèle de la halde dans calcul de sensibilités
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            tic
            for o=1:1
                clear SENSIBILITE
                SENSIBILITE=zeros(length(MAILLAGE(:,1)),length(DUOS(:,1)));
                for j=1:length(DUOS(:,1))
                    SENSIBILITE(:,j)=1/(4*pi^2)*Mat1(:,j)./(Mat2(:,DUOS(j,1)).*Mat2(:,DUOS(j,2)));
                    %SENSIBILITE_AVANCEMENT=round(j/length(DUOS(:,1))*100)
                end
            end
            toc
        end
    end
    
    %% I - 3 Affichage des valeurs rho app et simpl V2
    actif=1;
    for o=1
        if actif==1
            
            load Interpolation_DATA
            INDICE=10;
            
            p = get(gcf,'Position');
            set(0,'DefaultFigurePosition',p);
            rho_app=1;
            
            close all
            pas_de_temps=24/24;
            formatOut1 = 'dd/mm';
            formatOut2= 'dd/mm HH AM';
            format=formatOut1;
            
            T_MIN=min(CONFIG_FOCUS{1,1}(:,1));
            T_MAX=max(CONFIG_FOCUS{1,1}(:,1));
            BREAKER=0;
            CHOIX_MATRICE=zeros(1000,1);
            for i=872%1:1000
                if BREAKER<50
                    
                    figure('Color', [ 1 1 1])
                    %errorbar(CONFIG_FOCUS{1,i}(:,1),CONFIG_FOCUS{1,i}(:,9+(rho_app==1)*3),CONFIG_FOCUS{1,i}(:,9+(rho_app==1)*3).*CONFIG_FOCUS{1,i}(:,10+(rho_app==1)*3)/100,'.--','LineWidth',1.5,'MarkerSize',15)
                    %plot(CONFIG_FOCUS{1,i}(:,1),CONFIG_FOCUS{1,i}(:,9+(rho_app==1)*3),'o--')
                    plot(CONFIG_FOCUS{1,i}(:,1),abs(CONFIG_FOCUS{1,i}(:,9+(rho_app==1)*3)),'.k-','LineWidth',2,'MarkerSize',25)
                    hold on
                    % errorbar(CONFIG_FOCUS{1,i}(:,1),(CONFIG_FOCUS{1,i}(:,9+(rho_app==1)*3)),CONFIG_FOCUS{1,i}(:,9+(rho_app==1)*3).*CONFIG_FOCUS{1,i}(:,10+(rho_app==1)*3)/100/8,'.-','LineWidth',0.5,'Color','black','MarkerSize',0.25)
                    
                    
                    % Affichage interpolation
                    if isempty(Interpolation_DATA{i})==0
                        plot(Interpolation_DATA{i}(:,1),Interpolation_DATA{i}(:,2),'r--','LineWidth',2)
                    end
                    
                    
                    %xlim([T_MIN T_MAX])
                    ylabel({'Resistivité apparente avec ABEM';'(Ohm.m)'},'FontSize',14)
                    %     yyaxis right
                    %     plot(ARROSAGE(:,1),ARROSAGE(:,2),'.--','LineWidth',2,'MarkerSize',10)
                    %     ylabel({'Arrosage de la halde';'(Nb de passage par heure)'},'FontSize',14)
                    %     yyaxis left
                    grid
                    title(['Configuration n°',num2str(i),' : C1 = ',num2str(CONFIG_FOCUS{1,i}(1,2)),' ; C2 = ',num2str(CONFIG_FOCUS{1,i}(1,3)),' ; P1 = ',num2str(CONFIG_FOCUS{1,i}(1,4)),' ; P2 = ',num2str(CONFIG_FOCUS{1,i}(1,5))],'FontSize',16)
                    xlabel({['Date (format : ',format,')']},'FontSize',14)
                    %grid minor
                    ax = gca;
                    ax.XTick=[pas_de_temps*unique(round(CONFIG_FOCUS{1,i}(:,1)/pas_de_temps))];
                    ax.XTickLabel =[datestr(pas_de_temps*unique(round(CONFIG_FOCUS{1,i}(:,1)/pas_de_temps)),format)];
                    %grid minor
                    
                    CONFIGURATIONS_SELECT(1,1:4)=CONFIG_FOCUS{1,i}(1,2:5);
                    
                    % Calcul des sensibilités
                    
                    clear SYNTHESE_VALUES_LIMITE
                    C1_P1=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(1,1)&DUOS(:,2)==CONFIGURATIONS_SELECT(1,3)));
                    C2_P1=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(1,2)&DUOS(:,2)==CONFIGURATIONS_SELECT(1,3)));
                    C1_P2=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(1,1)&DUOS(:,2)==CONFIGURATIONS_SELECT(1,4)));
                    C2_P2=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(1,2)&DUOS(:,2)==CONFIGURATIONS_SELECT(1,4)));
                    SYNTHESE_VALUES_LIMITE(:,1)=abs(C1_P1-C2_P1-C1_P2+C2_P2);
                    
                    % Matrice de sensibilité pour le protocole limité
                    SENSIBILITE_LIMITE=MAILLAGE;
                    SENSIBILITE_LIMITE(:,4)=SYNTHESE_VALUES_LIMITE(:,1);
                    
                    
                    garde=0;
                    for j=1:length(SENSIBILITE_LIMITE(:,1))
                        if SENSIBILITE_LIMITE(j,3)<7.563+pente*(SENSIBILITE_LIMITE(j,1)-56.74)
                            garde(end+1,1)=j;
                        end
                    end
                    garde(1,:)=[];
                    SENSIBILITE_LIMITE_2=SENSIBILITE_LIMITE(garde,:);
                    
                    
                    % create smaller axes
                    for o=1
                        axes('Position',[.57 .6 .4 .4],'Visible','off')
                        box off
                        %figure('color',[1 1 1])
                        hold on
                        
                        SENSIBILITE_DATA=SENSIBILITE_LIMITE_2;
                        SENSIBILITE_DATA(:,4)=log(SENSIBILITE_DATA(:,4));
                        % Interpolation
                        clearvars F;
                        F = scatteredInterpolant(SENSIBILITE_DATA(:,1),SENSIBILITE_DATA(:,2),SENSIBILITE_DATA(:,3),SENSIBILITE_DATA(:,4),'natural');
                        vq = F(X,Y,Z);
                        ValAffichee = vq;
                        
                        % Suppression des données au dessus de la surface
                        for xi=1:length(X(1,:,1))
                            for yi=1:length(X(:,1,1))
                                for zi=1:length(X(1,1,:))
                                    if Z(yi,xi,zi)>7.563+pente*(X(yi,xi,zi)-56.74)+0.5
                                        ValAffichee(yi,xi,zi)=NaN;
                                    end
                                end
                            end
                        end
                        
                        % Mise en forme de la figure
                        daspect([1,1,1])
                        axis tight
                        ax = gca;
                        ax.FontSize = 13;
                        %view(0,0)
                        view(55,15)
                        light('Position',[40 -10 50],'Style','local')
                        camzoom(1.8)
                        camproj('perspective')
                        colormap (flipud(hot(10)));
                        cmap = colormap;
                        
                        
                        
                        % Affichage des volumes (UNE seule valeur de coupure)
                        Valeur=[-7;-5];
                        V_Max=-5;
                        V_Min=-10;
                        Valeur_Indice = round((Valeur-V_Min)*10/(V_Max-V_Min));
                        for ki=1:length(Valeur_Indice(:,1))
                            p1=patch(isocaps(X,Y,Z,ValAffichee,Valeur(ki,1),'enclose','above'),...
                                'FaceColor','interp','EdgeColor','none','FaceAlpha',0.7);
                            p1 = patch(isosurface(X,Y,Z,ValAffichee,Valeur(ki,1),'enclose','above'),...
                                'FaceColor',cmap(Valeur_Indice(ki,1),:),'EdgeColor','none','FaceAlpha',0.7);
                        end
                        
                        
                        % Affichage des électrodes (approximation halde rectangulaire)
                        for j=1:length(ELEC(:,1))
                            plot3(ELEC(j,1),ELEC(j,2),ELEC(j,3),'k.','MarkerSize',7.5)
                        end
                        for j=1:length(ELEC_FAUSSES(:,1))
                            plot3(ELEC(ELEC_FAUSSES(j,1),1),ELEC(ELEC_FAUSSES(j,1),2),ELEC(ELEC_FAUSSES(j,1),3),'.r','MarkerSize',7.5)
                        end
                        for j=1:length(ELEC_MAUVAISES(:,1))
                            plot3(ELEC(ELEC_MAUVAISES(j,1),1),ELEC(ELEC_MAUVAISES(j,1),2),ELEC(ELEC_MAUVAISES(j,1),3),'.m','MarkerSize',7.5)
                        end
                        
                        % Limites de la halde
                        xlim([20 110]);
                        %                 ylim([21 31]);
                        %                 zlim([1 9]);
                        plot3(Maillage3DSurface_2(:,1),Maillage3DSurface_2(:,2),Maillage3DSurface_2(:,3),'-k','LineWidth',0.875)
                        %axes('Color','none','XColor','none');
                        
                    end
                    
                    %BREAKER=BREAKER+1;
                    
                    
                    % Choix de garder les données ou pas
                    for o=1
                        %                         options.Interpreter = 'tex';
                        %                         % Include the desired Default answer
                        %                         options.Default = 'Garder';
                        %                         % Use the TeX interpreter in the question
                        %                         qstring = 'Que voulez vous faire avec les données interpolées';
                        %                         choice = questdlg(qstring,'Choix',...
                        %                             'Garder','Rééditer','Jeter',options)
                        %
                        %                         % Choix garder = 2
                        %                         if length(choice)==6
                        %                             CHOIX_MATRICE(i,1)=1;
                        %
                        %                             % Choix rééditer = 2
                        %                         elseif length(choice)==8
                        %                             CHOIX_MATRICE(i,1)=2;
                        %
                        %                             % Choix jeter = 3
                        %                         elseif length(choice)==5
                        %                             CHOIX_MATRICE(i,1)=3;
                        %                         end
                    end
                end
                %close
            end
            
            for o=1 % Affichage des données hydro
                %                             for o=1
                %                                 %%
                %                                 pas_de_temps=24/24;
                %                                 figure('Color', [ 1 1 1])
                % %                                 for i=INDICE:INDICE
                % %                                     plot(RAW_DATA_HYDRO{1}(:,1),RAW_DATA_HYDRO{1}(:,i+1),'.--k','LineWidth',1,'MarkerSize',1)
                % %                                     hold on
                % %                                 end
                %
                %                                 ylabel({'Resistivité mesurée avec GS3';'(Ohm.m)'},'FontSize',14)
                %                                 %yyaxis right
                %                                 plot(ARROSAGE(:,1),ARROSAGE(:,2),'.-k','LineWidth',2,'MarkerSize',20)
                %                                 ylabel({'Arrosage de la halde';'(Nb de passage par heure)'},'FontSize',14)
                %                                % yyaxis left
                %                                 grid
                %                                 %title(['Résistivité apparente mesurées par les GS3 dans le lysimètre N°',num2str(floor((i+1)/2))],'FontSize',16)
                %                                 title('Arrosage de la halde par le camion à eau dans la nuit du 7 au 8 juin','FontSize',16)
                %                                 xlabel({['Date (format : ',format,')']},'FontSize',14)
                %                                 grid minor
                %                                 ax = gca;
                %                                 ax.XTick=[pas_de_temps*unique(round(CONFIG_FOCUS{10}(:,1)/pas_de_temps))];
                %                                 ax.XTickLabel =[datestr(pas_de_temps*unique(round(CONFIG_FOCUS{10}(:,1)/pas_de_temps)),format)];
                %                                 grid minor
                %                                  xlim([T_MIN T_MAX])
                %                                 %xlim([42892.5 42894])
                %                                 hold on
                %                                 for lignei=1:length(CONFIG_FOCUS{10}(:,1))
                %                                     line([CONFIG_FOCUS{10}(lignei,1) CONFIG_FOCUS{10}(lignei,1)],[0 18],'color','b','linestyle','--','LineWidth',1)
                %                                 end
                %                                 plot(CONFIG_FOCUS{10}(:,1),zeros(length(CONFIG_FOCUS{10}(:,1)),1),'.b','Markersize',20)
                %                                 %%
                %                             end
                %
            end
            
            garde_rho_app_2=0;
            for i=1:1000
                if min((CONFIG_FOCUS{1,i}(:,12)))>20
                    garde_rho_app_2(end+1,1)=i;
                end
            end
            garde_rho_app_2(1,:)=[];
        end
    end
    
    %% I - 4 Simplification des courbes
    actif=0;
    for o=1
        if actif==1
            clear User_Points
            Nb_User_Points=20;
            for i=1:Nb_User_Points
                User_Points(i,1:2)=ginput(1);
                User_Points=sortrows(User_Points,1);
                plot(User_Points(:,1),User_Points(:,2),'.-r','MarkerSize',15,'LineWidth',2)
            end
            % Choix de la configuration
            prompt = {sprintf('Quelle est la configuration étudiée ?')};
            dlg_title = 'Choix Configuration';
            num_lines = 1;
            defaultans = {'0'};
            Config = inputdlg(prompt,dlg_title,num_lines,defaultans);
            Config = str2num(Config{:});
            Interpolation_DATA{Config}=User_Points;
            a=Interpolation_DATA;
        end
    end
    
    %% I - 5 Rédaction de la matrice de données interpolées NOUVELLE
    actif=1;
    for o=1
        if actif==1
            close all
            
            T_MIN=min(CONFIG_FOCUS{1,1}(:,1));
            T_MAX=max(CONFIG_FOCUS{1,1}(:,1));
            load CHOIX_MATRICE.mat
            
            load Interpolation_DATA.mat
            frequence_acquisition=1; % fréquence d'acquisition (en h)
            intervalle_temps=frequence_acquisition/24;
            T_interp=(floor(T_MIN):intervalle_temps:floor(T_MAX+1))';
            
            DATA_interp_R=zeros(length(Interpolation_DATA),length(T_interp)+4);
            
            affichage=0;
            BREAKER=0;
            CHOIX_MATRICE_1=find(CHOIX_MATRICE(:,1)==1);
            for i=1:length(CHOIX_MATRICE_1)
                % Pas de court breaker si pas d'affichage
                if affichage==0
                    BREAKER=0;
                end
                
                if BREAKER<100
                    ind=CHOIX_MATRICE_1(i,1);
                    DATA_interp_R(ind,1:4)=CONFIG_FOCUS{1,ind}(1,2:5);
                    
                    K=CONFIG_FOCUS{1,ind}(1,11);
                    clear Interpolation_DATA_2
                    Interpolation_DATA_2=unique(Interpolation_DATA{1,ind}(:,1),'rows');
                    for j=1:length(Interpolation_DATA_2)
                        trouve=find(Interpolation_DATA{1,ind}(:,1)==Interpolation_DATA_2(j,1));
                        Interpolation_DATA_2(j,2)=Interpolation_DATA{1,ind}(trouve(1,1),2);
                    end
                    R_Interp=interp1(Interpolation_DATA_2(:,1),Interpolation_DATA_2(:,2),T_interp);
                    R_Interp=R_Interp/K;
                    
                    DATA_interp_R(ind,5:end)=R_Interp';
                    
                    
                    if affichage==1
                        figure('Color', [ 1 1 1])
                        plot(CONFIG_FOCUS{1,ind}(:,1),CONFIG_FOCUS{1,ind}(:,9),'.k--','MarkerSize',20,'LineWidth',1.5)
                        hold on
                        title(['Configuration n°',num2str(ind),' C1=',num2str(DATA_interp_R(ind,1)),' C2=',num2str(DATA_interp_R(i,2)),' P1=',num2str(DATA_interp_R(i,3)),' P2=',num2str(DATA_interp_R(i,4))],'FontSize',16)
                        grid
                        plot(T_interp(:,1),DATA_interp_R(ind,5:end)','.-r','MarkerSize',5)
                        %plot(T_mesure(:,1),R_mesure(:,1),'og')
                        ylabel({'Résistance mesurée avec ABEM';'(Ohm)'},'FontSize',14)
                        %     yyaxis right
                        %     plot(ARROSAGE(:,1),ARROSAGE(:,2),'.--','LineWidth',2,'MarkerSize',10)
                        %     ylabel({'Arrosage de la halde';'(Nb de passage par heure)'},'FontSize',14)
                        %     yyaxis left
                        title('Comparaison entre les mesures (en noir) et les données interpolées (en rouge)','FontSize',16)
                        xlabel({['Date (format : ',format,')']},'FontSize',14)
                        grid minor
                        ax = gca;
                        ax.XTick=[pas_de_temps*unique(round(CONFIG_FOCUS{1,ind}(:,1)/pas_de_temps))];
                        ax.XTickLabel =[datestr(pas_de_temps*unique(round(CONFIG_FOCUS{1,ind}(:,1)/pas_de_temps)),format)];
                        grid minor
                    end
                    BREAKER=BREAKER+1;
                end
            end
            
        end
    end
    
    %% I - 6 Rédaction du document time-lapse pour inversion
    actif=1;
    for o=1
        if actif==1
            ecart_type_mesure=2;
            DATA_interp_R_1=DATA_interp_R;
            garde=0;
            for i=1:length(DATA_interp_R_1(1,:))
                trouve=isnan(DATA_interp_R_1(:,i));
                trouve_2=find(trouve(:,1)==1);
                if isempty(trouve_2)
                    garde(end+1,1)=i;
                end
            end
            garde(1,:)=[];
            DATA_interp_R_2=DATA_interp_R_1(:,garde');
            T_interp_2=T_interp(garde(5:end)-4,:);
            
            DATA_interp_R_2(DATA_interp_R_2(:,1)==0,:)=[];
            DATA_interp_R_3=DATA_interp_R_2;
            
            % Rédaction des SRV files
            load SRV_elec.mat;
            for i=1:length(T_interp_2)
                Name_Survey=['halde_4D_',num2str(i)];
                fileID = fopen([Name_Survey,'.srv'],'w');
                fprintf(fileID,'192 \r\n');
                for j=2:length(SRV_elec)
                    fprintf(fileID,'%6d %6.8f %6.8f %6.8f %6d \r\n',SRV_elec(j,:));
                end
                fprintf(fileID,'%6d \r\n',length(DATA_interp_R_3(:,1)));
                for j=1:length(DATA_interp_R_3(:,1))
                    %ligne=[j,CONFIG_TOT(j,:),DATA_interp_R_2(j,i),erreur_interp_R(j,1)];
                    ligne=[j,DATA_interp_R_3(j,1:4),DATA_interp_R_3(j,i+4),ecart_type_mesure];
                    fprintf(fileID,'%6d %6d %6d %6d %6d %6.8f %6.8f \r\n',ligne);
                end
                fclose(fileID);
            end
            
            
            % Conversion du temps en h (différentiel)
            T_min_2=min(T_interp_2);
            T_interp_2_h=T_interp_2-T_min_2;
            T_interp_2_h=T_interp_2_h*24;
            
            % Rédaction du time_lapse_survey_list
            Name_survey_list=['time_lapse_survey_list_',num2str(T_min_2)];
            fileID = fopen([Name_survey_list,'.txt'],'w');
            fprintf(fileID,'%6d \r\n',length(T_interp_2(:,1)));
            for i=1:length(T_interp_2(:,1))
                fprintf(fileID,'%s %6d \r\n',['halde_4D_',num2str(i),'.srv'],T_interp_2_h(i));
            end
            
            % Rédaction du fichier de commande pour concaténation du .exo
            fileID = fopen(['Concatenation_exo_',num2str(frequence_acquisition),'h.txt'],'w');
            fprintf(fileID,'%s \r\n',['bx3d -f haldeVF.1 tl_sig',num2str(T_interp_2_h(1)),'.000 haldeVF_timelapse_1.5.exo 1']);
            Results_name{1}=['tl_sig',num2str(T_interp_2_h(1)),'.000'];
            for i=2:length(T_interp_2(:,1))
                if round(T_interp_2_h(i),0)==round(T_interp_2_h(i),3);
                    fprintf(fileID,'%s \r\n',['bx3d -af haldeVF.1 tl_sig',num2str(T_interp_2_h(i)),'.000 haldeVF_timelapse_1.5.exo ',num2str(i)]);
                    Results_name{i}=['tl_sig',num2str(T_interp_2_h(i)),'.000'];
                else
                    fprintf(fileID,'%s \r\n',['bx3d -af haldeVF.1 tl_sig',num2str(T_interp_2_h(i)),'00 haldeVF_timelapse_1.5.exo ',num2str(i)]);
                    Results_name{i}=['tl_sig',num2str(T_interp_2_h(i)),'00'];
                end
            end
        end
    end
end

%% --------------------- II : APRÈS INVERSION -----------------------------
for o=1
    %% II - 1 Récupération des données après inversion avec E4D
    actif=1;
    NB_INVERSIONS=242;
    for o=1
        verification=1;
        time_lapse=1;
        fichier_data='DATA_REG';
        load GS3_location
        
        if actif==1
            clear Results_E4D
            for o=1 % Récupération des données d'inversion
                if time_lapse==1
                    L_results=length(csvread(Results_name{1}));
                    Results_E4D=zeros(L_results,length(Results_name)+1);
                    for i=4:L_results
                        Results_E4D(i,1)=i-3;
                    end
                    
                    for i=1:min(length(Results_name),NB_INVERSIONS)
                        Results_E4D(:,i+1)=csvread(Results_name{i});
                        AVANCEMENT_RECUPERATION=round(i/min(length(Results_name),NB_INVERSIONS)*100)
                    end
                    
                    % Conversion des données en Ohm.m
                    Results_E4D_R=Results_E4D;
                    for i=2:length(Results_name)
                        Results_E4D_R(4:end,i)=1./Results_E4D(4:end,i);
                    end
                    
                else
                    % time lapse == 0 => 1 fichier de données unique
                    Results_E4D_raw=xlsread([fichier_data,'.xlsx'],1);
                    Results_E4D=zeros(3+length(Results_E4D_raw(:,1))-1,2);
                    for i=1:length(Results_E4D_raw(:,1))-1
                        Results_E4D(i+3,1)=i;
                    end
                    Results_E4D(1:3,2)=Results_E4D_raw(1,:)';
                    Results_E4D(4:end,2)=Results_E4D_raw(2:end,1);
                    % Conversion des données en Ohm.m
                    Results_E4D_R=Results_E4D;
                    Results_E4D_R(4:end,2)=1./Results_E4D(4:end,2);
                    
                end
            end
            
            for o=1 % Récupération des données de maillage
                % haldeVF.1.node
                NODE_raw=xlsread('NODE.xlsx',1);
                %load NODE_raw.mat
                NODE=NODE_raw(2:end,1:4);
                % CORRECTION DES COORDONNÉES
                %         % 1e limites
                %         CORR_X=34.546+21.740;
                %         CORR_Y=26.059-0.694;
                %         CORR_Z=8.242-4.232;
                %                 % 2e limites
                %                 CORR_X=34.546+23.286;
                %                 CORR_Y=26.059+0.435;
                %                 CORR_Z=8.242-2.25;
                %         % 3e limites
                %         CORR_X=34.546+22.09;
                %         CORR_Y=26.059-0.6657;
                %         CORR_Z=8.242-4.179;
                %         % 4e limites (TEST INV STATIQUE REGULARISEE)
                %         CORR_X=34.546+22.04;
                %         CORR_Y=26.059-0.666;
                %         CORR_Z=8.242-4.179;
                %                             % 5e limites (Version finale halde)
                %                             CORR_X=34.64+23.19;
                %                             CORR_Y=21.99+4.512;
                %                             CORR_Z=8.177-2.185;
                % 6e limites
                CORR_X=34.64+21.69;
                CORR_Y=21.99+3.387;
                CORR_Z=8.177-4.173;
                %                             % inv de 244 images
                %                             CORR_X=34.64+23.19;
                %                             CORR_Y=21.99+4.512;
                %                             CORR_Z=8.177-2.185;
                
                
                
                % haldeVF.1.ele
                ELEMENT_raw=xlsread('ELEMENT.xlsx',1);
                %load ELEMENT_raw.mat
                ELEMENT=ELEMENT_raw(2:end,1:5);
                L_ELEMENT=length(ELEMENT(:,1));
                
            end
            
            for o=1 % VÉFICATION de la correction des coordonnées
                if verification==1
                    figure('Color', [ 1 1 1])
                    plot3(ELEC(:,1),ELEC(:,2),ELEC(:,3),'.r','MarkerSize',5)
                    hold on
                    plot3(NODE(:,2),NODE(:,3),NODE(:,4),'.k')
                    title('AVANT')
                    %                     xlim([-22 -21])
                    %                     ylim([-4 -2])
                    %                     zlim([-20 20])
                end
                
                NODE(:,2)=NODE(:,2)+CORR_X;
                NODE(:,3)=NODE(:,3)+CORR_Y;
                NODE(:,4)=NODE(:,4)+CORR_Z;
                
                % VÉRIFICATION
                if verification==1
                    figure('Color', [ 1 1 1])
                    plot3(ELEC(:,1),ELEC(:,2),ELEC(:,3),'.r','MarkerSize',5)
                    hold on
                    plot3(NODE(:,2),NODE(:,3),NODE(:,4),'.k')
                    title('APRES')
                end
            end
            
            for o=1 % Calcul des éléments du maillage matlab
                % Création du maillage E4D pour matlab
                clear Node_Element
                for i=1:4
                    Node_Element{i}(:,1:3)=NODE(ELEMENT(:,i+1),2:4);
                end
                
                % Calcul des barycentres
                clear Barycentre
                for i=1:max(ELEMENT(:,1))
                    Barycentre(i,1)=i;
                end
                Barycentre(:,2:4)=(Node_Element{1}(:,1:3)+Node_Element{2}(:,1:3)+Node_Element{3}(:,1:3)+Node_Element{4}(:,1:3))/4;
            end
            
        end
    end
    
    %% II - 2 Affichage des données de resistivite
    actif=1;
    for o=1
        if actif==1
            close all
            
            for o=1
                load GS3_location.mat
                
                %         % LYSI 1
                %         Xmin=37;
                %         Xmax=38;
                %         Ymin=24.9;
                %         Ymax=25.9;
                %         Zmin=5;
                
                % % LYSI 2
                % Xmin=47.1;
                % Xmax=48.1;
                % Ymin=25.6;
                % Ymax=26.6;
                % Zmin=5;
                
                %             % LYSI 3
                %             Xmin=57.2;
                %             Xmax=58.2;
                %             Ymin=26.6;
                %             Ymax=27.6;
                %             Zmin=1.7;
                
                % LIGNE
                Xmin=30;
                Xmax=95;
                Ymin=26.8;
                Ymax=27.2;
                Zmin=4;
                
                %         % LYSI 4
                %         Xmin=67.5;
                %         Xmax=68.5;
                %         Ymin=25.7;
                %         Ymax=26.7;
                %         Zmin=5;
                
                %         % LYSI 5
                %         Xmin=77.5;
                %         Xmax=78.5;
                %         Ymin=25.1;
                %         Ymax=26.1;
                %         Zmin=4;
                
                %         % LYSI 6
                %         Xmin=87.8;
                %         Xmax=88.8;
                %         Ymin=24.4;
                %         Ymax=25.4;
                %         Zmin=3;
                
                
                ELEMENT_SELECT=Barycentre(find(Barycentre(:,2)>Xmin & Barycentre(:,2)<Xmax & Barycentre(:,3)>Ymin & Barycentre(:,3)<Ymax & Barycentre(:,4)>Zmin),:);
                %plot3(ELEMENT_SELECT(:,2),ELEMENT_SELECT(:,3),ELEMENT_SELECT(:,4),'.k')
                
                % FILTRAGE APPARTENANCE ANORTHOSITE
                ELEMENT_SELECT_2=[ELEMENT_SELECT,zeros(length(ELEMENT_SELECT),1)];
                for i=1:length(ELEMENT_SELECT)
                    ele_id=ELEMENT_SELECT(i,1);
                    if ELEMENT_raw(ele_id+1,6)==1
                        ELEMENT_SELECT_2(i,5)=1;
                    end
                end
                ELEMENT_SELECT_2(ELEMENT_SELECT_2(:,5)==0,:)=[];
            end
            %%
            time=10;
            %load DATA_TO_PLOT
            ELEMENT_SELECT=ELEMENT_SELECT_2;
            DATA_TO_PLOT=zeros(length(ELEMENT_SELECT(:,1)),1);
            for i=1:length(ELEMENT_SELECT(:,1))
                DATA_TO_PLOT(i,1:4)=ELEMENT_SELECT(i,1:4);
                DATA_TO_PLOT(i,5)=Results_E4D_R(find( Results_E4D_R(:,1)== ELEMENT_SELECT(i,1)),1+time);
                [1,round(i/length(ELEMENT_SELECT(:,1))*100)]
            end
            
            DATA_TO_PLOT(:,6)=log(DATA_TO_PLOT(:,5));
            
            % Affichage de l'histogramme des données log
            figure('Color', [ 1 1 1])
            histogram(DATA_TO_PLOT(DATA_TO_PLOT(:,6)<12,6),100)
            title('Histogramme de valeurs de résistivité (Ohm.m)','FontSize',16)
            %             xlabel('Valeur de résistivité en Ohm.m')
            %             ylabel('Nombre de valeurs dans chaque catégories')
            axis off
            TicksM = [2;4;6;8;10;12;14;16];
            TicksL = round(exp(TicksM),0);
            ax = gca;
            ax.XTick=[2;4;6;8;10;12;14;16];
            ax.XTickLabel =round(exp(TicksM),0);
            grid
            grid minor
            
            % Troncature MIN au choix de l'utilisateur
            p = get(gcf,'Position');
            for o=1
                d = dialog('Position',[p(1)+800,p(2)+300,400,400],'Name','Choix de la valeur minimale de resistivité');
                
                txt = uicontrol('Parent',d,...
                    'Style','text',...
                    'Position',[100 200 210 80],...
                    'String',['Select the minimum resistivity value needed in Ohm.m (log values)'],...
                    'Fontsize',10);
                
                btn = uicontrol('Parent',d,...
                    'Position',[170 20 70 25],...
                    'String','Close',...
                    'Callback','delete(gcf)');
            end % Dialog box
            
            CutOff_MIN=ginput(1);
            CutOff_MIN=round(CutOff_MIN(:,1),2);
            
            % Troncature MAX au choix de l'utilisateur
            p = get(gcf,'Position');
            for o=1
                d = dialog('Position',[p(1)+800,p(2)+300,400,400],'Name','Choix de la valeur maximale de resistivité');
                
                txt = uicontrol('Parent',d,...
                    'Style','text',...
                    'Position',[100 200 210 80],...
                    'String',['Select the maximum resistivity value needed in Ohm.m (log values)'],...
                    'Fontsize',10);
                
                btn = uicontrol('Parent',d,...
                    'Position',[170 20 70 25],...
                    'String','Close',...
                    'Callback','delete(gcf)');
            end % Dialog box
            
            CutOff_MAX=ginput(1);
            CutOff_MAX=round(CutOff_MAX(:,1),2);
            
            close
            % echelle de couleur de 0 a 1
            % echelle de valeur de R_min a R_max
            DATA_TO_PLOT(:,7)=DATA_TO_PLOT(:,6);
            DATA_TO_PLOT(DATA_TO_PLOT(:,7)<=CutOff_MIN,7)=CutOff_MIN;
            
            DATA_TO_PLOT(DATA_TO_PLOT(:,7)>=CutOff_MAX,7)=CutOff_MAX;
            
            DATA_TO_PLOT(:,7)=DATA_TO_PLOT(:,7)-CutOff_MIN;
            
            DATA_TO_PLOT(:,7)=round(DATA_TO_PLOT(:,7)/(CutOff_MAX-CutOff_MIN)*100);
            % 0->1
            DATA_TO_PLOT(DATA_TO_PLOT(:,7)==0,7)=1;
            
            figure('Color', [ 1 1 1])
            colormap ((jet(100)));
            cmap = colormap;
            for i=1:length(DATA_TO_PLOT(:,1))
                ind_color=DATA_TO_PLOT(i,7);
                plot3(DATA_TO_PLOT(i,2),DATA_TO_PLOT(i,3),DATA_TO_PLOT(i,4),'.','Color',[cmap(ind_color,1) cmap(ind_color,2) cmap(ind_color,3)])
                hold on
                [2,round(i/length(DATA_TO_PLOT(:,1))*100)]
            end
            daspect([1 1 1])
            plot3(Maillage3DSurface_2(:,1),Maillage3DSurface_2(:,2),Maillage3DSurface_2(:,3),'-k','LineWidth',0.875)
            plot3(ELEC(:,1),ELEC(:,2),ELEC(:,3),'k.','MarkerSize',7.5)
            
            % Colorbar
            % Légende
            clear colorbar
            colormap ((jet(100)));
            colorbar;
            caxis([0 100]);
            TicksM = [1;20;40;60;80;100];
            TicksL = round(exp((TicksM/100)*(CutOff_MAX-CutOff_MIN)+CutOff_MIN),0);
            
            
            c=colorbar;
            c.Label.String = 'Resistance entre les électrodes C1 et C2 (Ohms)';
            c.Label.FontWeight='bold';
            c.Label.FontSize=14;
            c.Ticks=TicksM;
            c.TickLabels={num2str(TicksL)};
            c.Location='south';
            
            plot3(GS3_location(:,2),GS3_location(:,3),GS3_location(:,4),'.k','MarkerSize',10)
            
            
            plot3(Maillage3DSurface_2(:,1),Maillage3DSurface_2(:,2),Maillage3DSurface_2(:,3),'-k','LineWidth',0.875)
            axis off
        end
    end
    
    %% II - 2b AFFICHAGE DATA RES LONG #1
    for o=1
        p = get(gcf,'Position');
        set(0,'DefaultFigurePosition',p);
        close all
        load DATA_RES_LONG
        
        % 200 Ohms.m
        VWC_CALC=((1./DATA_RES_LONG(:,2))+0.0003)/(3*10^-5);
        
        % 150 Ohms.m
        %VWC_CALC=((1./DATA_RES_LONG(:,2))+0.0003)/(4*10^-5);
        
        % 100 Ohms.m
        %VWC_CALC=((1./DATA_RES_LONG(:,2))+0.0004)/(6*10^-5);
        
        
        figure('Color', [ 1 1 1])
        
        plot(DATA_RES_LONG(:,1)-32.5,VWC_CALC(:,1),'-k.','linewidth',1.5)
        grid
        grid minor
        hold on
        load DATA_VWC_LONG
        GS3_LONG=GS3_location([5,12,19,26,33,40],2);
        % yyaxis right
        plot(GS3_LONG(:,1)-32.5,DATA_VWC_LONG(1,2:7)*100,'.--b','MarkerSize',30,'linewidth',3)
        hold on
        
        %legend('VWC calculated from 3D geoelectrical monitoring and petrophysical relationship (%)','VWC measured by punctual GS3 probes (%)','FontSize',14)
        ylabel({'Volumetric moisture content','(%)'},'FontSize',14,'FontWeight','bold')
        xlabel({'Distance from upslope','(meters)',''},'FontSize',14,'FontWeight','bold')
        
        ylim([14 50])
        xlim([0 60])
        
        text(25,40,'Image #1 : 06/06 12:00','FontSize',16)
    end
    
    %% II - 2b AFFICHAGE DATA RES LONG #2
    for o=1
        p = get(gcf,'Position');
        set(0,'DefaultFigurePosition',p);
        close all
        load DATA_RES_LONG
        
        % 200 Ohms.m
        VWC_CALC=((1./DATA_RES_LONG(:,5))+0.0003)/(3*10^-5);
        
        % 150 Ohms.m
        %VWC_CALC=((1./DATA_RES_LONG(:,2))+0.0003)/(4*10^-5);
        
        % 100 Ohms.m
        %VWC_CALC=((1./DATA_RES_LONG(:,2))+0.0004)/(6*10^-5);
        
        % 20 Ohms.m
        %VWC_CALC=((1./DATA_RES_LONG(:,5))+0.0031)/(0.0003);
        
        % 10 Ohms.m
        %VWC_CALC=((1./DATA_RES_LONG(:,5))+0.001)/(0.00005);
        
        
        % 50 Ohms.m
        %VWC_CALC=((1./DATA_RES_LONG(:,7))+0.0008)/(0.0001);
        
        figure('Color', [ 1 1 1])
        
        plot(DATA_RES_LONG(:,1)-32.5,VWC_CALC(:,1),'-k.','linewidth',1.5)
        grid
        grid minor
        hold on
        load DATA_VWC_LONG
        GS3_LONG=GS3_location([5,12,19,26,33,40],2);
        % yyaxis right
        plot(GS3_LONG(:,1)-32.5,DATA_VWC_LONG(2,2:7)*100,'.--b','MarkerSize',30,'linewidth',3)
        hold on
        
        %legend('VWC calculated from 3D geoelectrical monitoring and petrophysical relationship (%)','VWC measured by punctual GS3 probes (%)','FontSize',14)
        ylabel({'Volumetric moisture content','(%)'},'FontSize',14,'FontWeight','bold')
        xlabel({'Distance from upslope','(meters)',''},'FontSize',14,'FontWeight','bold')
        
        ylim([14 50])
        xlim([0 60])
        
        text(25,40,'Image #2 : 08/06 04:00','FontSize',16)
    end
    
    %% II - 2b AFFICHAGE DATA RES LONG #3
    for o=1
        p = get(gcf,'Position');
        set(0,'DefaultFigurePosition',p);
        close all
        load DATA_RES_LONG
        
        % 200 Ohms.m
        VWC_CALC=((1./DATA_RES_LONG(:,7))+0.0003)/(3*10^-5);
        
        % 150 Ohms.m
        %VWC_CALC=((1./DATA_RES_LONG(:,2))+0.0003)/(4*10^-5);
        
        % 100 Ohms.m
        %VWC_CALC=((1./DATA_RES_LONG(:,2))+0.0004)/(6*10^-5);
        
        % 20 Ohms.m
        %VWC_CALC=((1./DATA_RES_LONG(:,5))+0.0031)/(0.0003);
        
        % 10 Ohms.m
        %VWC_CALC=((1./DATA_RES_LONG(:,5))+0.001)/(0.00005);
        
        
        % 50 Ohms.m
        %VWC_CALC=((1./DATA_RES_LONG(:,7))+0.0008)/(0.0001);
        
        figure('Color', [ 1 1 1])
        
        plot(DATA_RES_LONG(:,1)-32.5,VWC_CALC(:,1),'-k.','linewidth',1.5)
        grid
        grid minor
        hold on
        load DATA_VWC_LONG
        GS3_LONG=GS3_location([5,12,19,26,33,40],2);
        % yyaxis right
        plot(GS3_LONG(:,1)-32.5,DATA_VWC_LONG(3,2:7)*100,'.--b','MarkerSize',30,'linewidth',3)
        hold on
        
        %legend('VWC calculated from 3D geoelectrical monitoring and petrophysical relationship (%)','VWC measured by punctual GS3 probes (%)','FontSize',14)
        ylabel({'Volumetric moisture content','(%)'},'FontSize',14,'FontWeight','bold')
        xlabel({'Distance from upslope','(meters)',''},'FontSize',14,'FontWeight','bold')
        
        ylim([14 50])
        xlim([0 60])
        
        text(25,40,'Image #3 : 14/06 00:00','FontSize',16)
    end
    
    
    %% II - 3 Calcul des données de resistivite dans le temps aux GS3
    actif=1;
    for o=1
        if actif==1
            GS3_DATA_E4D=GS3_location;
            if time_lapse==1
                for i=1:length(GS3_location)
                    GS3_Coord=[ones(length(Barycentre(:,1)),1)*GS3_location(i,2),ones(length(Barycentre(:,1)),1)*GS3_location(i,3),ones(length(Barycentre(:,1)),1)*GS3_location(i,4)];
                    dist=sqrt((GS3_Coord(:,1)-Barycentre(:,2)).^2+(GS3_Coord(:,2)-Barycentre(:,3)).^2+(GS3_Coord(:,3)-Barycentre(:,4)).^2);
                    Bar_ID=Barycentre(find(dist(:,1)==min(dist(:,1))),1);
                    GS3_ResData=[Results_E4D_R(find(Results_E4D_R(:,1)==Bar_ID),1:end-1)];
                    
                    GS3_DATA_E4D(i,5:5+length(GS3_ResData(1,:))-1)=GS3_ResData;
                end
            else
                for i=1:length(GS3_location)
                    GS3_Coord=[ones(length(Barycentre(:,1)),1)*GS3_location(i,2),ones(length(Barycentre(:,1)),1)*GS3_location(i,3),ones(length(Barycentre(:,1)),1)*GS3_location(i,4)];
                    dist=sqrt((GS3_Coord(:,1)-Barycentre(:,2)).^2+(GS3_Coord(:,2)-Barycentre(:,3)).^2+(GS3_Coord(:,3)-Barycentre(:,4)).^2);
                    Bar_ID=Barycentre(find(dist(:,1)==min(dist(:,1))),1);
                    GS3_ResData=[Results_E4D_R(find(Results_E4D_R(:,1)==Bar_ID),1:2)];
                    
                    GS3_DATA_E4D(i,5:6)=GS3_ResData;
                end
            end
        end
    end
    
    %% II - 4 Superposition des données E4D et des données mesurées GS3
    actif=1;
    for o=1
        if actif==1
            p = get(gcf,'Position');
            set(0,'DefaultFigurePosition',p);
            close all
            load T_GS3.mat
            load GS3_DATA_mes.mat
            load T_GS3_RES_EAU.mat
            load GS3_DATA_EAU_mes.mat
            
            % Résistivité du sol
            GS3_DATA=GS3_DATA_E4D(:,1:5);
            for i=1:length(GS3_DATA_mes(:,1))
                data_interp_gs3=interp1(T_GS3,GS3_DATA_mes(i,5:end),T_interp_2);
                GS3_DATA(i,6:length(T_interp_2)+5)=data_interp_gs3';
            end
            
            % Résistivité de l'Eau
            GS3_DATA_EAU=GS3_DATA_E4D(:,1:5);
            for i=1:length(GS3_DATA_EAU_mes(:,1))
                data_interp_gs3=interp1(T_GS3_RES_EAU,GS3_DATA_EAU_mes(i,5:end),T_interp_2);
                GS3_DATA_EAU(i,6:length(T_interp_2)+5)=data_interp_gs3';
            end
            
            
            pas_de_temps=1;
            format=formatOut1;
            
            
            % Matrices d'informations
            LYSI_INFO{1}=['Lysimètre 1'];
            LYSI_INFO{2}=['Lysimètre 2'];
            LYSI_INFO{3}=['Lysimètre 3'];
            LYSI_INFO{4}=['Lysimètre 4'];
            LYSI_INFO{5}=['Lysimètre 5'];
            LYSI_INFO{6}=['Lysimètre 6'];
            
            NOM_SONDE{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE{2}=['Ilmenite Haut, Z = 1.2 m'];
            NOM_SONDE{1}=['Ilmenite Bas, Z = 1.5 m'];
            NOM_SONDE{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE{7}=['Sable Base N2, Z = 7 m'];
            
            NOM_SONDE_an{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE_an{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE_an{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE_an{2}=['Anorthosite Haut, Z = 1.2 m'];
            NOM_SONDE_an{1}=['Anorthosite Bas, Z = 1.5 m'];
            NOM_SONDE_an{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE_an{7}=['Sable Base N2, Z = 7 m'];
            
            load    GS3_DATA_E4D_avec_lysi.mat
            load T_interp_2_avec_lysi.mat
            load    GS3_DATA_E4D_sans_lysi.mat
            load T_interp_2_sans_lysi.mat
            % FIGURES
            for lysi=4
                for sonde=1:5
                    
                    ind_ligne=(lysi-1)*7+sonde;
                    figure('Color', [ 1 1 1])
                    hold on
                    
                    % Res mesurée E4D
                    if time_lapse==1
                        plot(T_interp_2(1:end-1,1),GS3_DATA_E4D(ind_ligne,6:end)','.-','LineWidth',4,'MarkerSize',10)
                    else
                        plot(T_interp_2(1,1),GS3_DATA_E4D(ind_ligne,6)','.','LineWidth',4,'MarkerSize',20)
                    end
                    %plot(T_interp_2_sans_lysi(1:end-1,1),GS3_DATA_E4D_sans_lysi(ind_ligne,6:end)','.-','LineWidth',4,'MarkerSize',10)
                    ylabel({'Resistiviy calculated after inversion (E4D)';'(\Omega.m)'},'FontSize',14,'FontWeight','bold')
                    
                    
                    yyaxis right
                    % Res mesurée GS3
                    plot(T_interp_2(1:end,1),GS3_DATA(ind_ligne,6:end)','.-','LineWidth',4,'MarkerSize',10)
                    ylabel({'Résistivité GS3';'(\Omega.m)'},'FontSize',14,'FontWeight','bold')
                    
                    
                    
                    % ylim([0 6000])
                    
                    hold on
                    
                    xlabel({'Elapsed time (dd/mm/yy)'},'FontSize',14,'FontWeight','bold')
                    if time_lapse==1
                        title_spec='COMPARAISON TIME-LAPSE : ';
                    else
                        title_spec='COMPARAISON STATIQUE : ';
                    end
                    % title([title_spec,LYSI_INFO{lysi},' : ',NOM_SONDE{sonde},' (rms = ',num2str(round(ERREUR)),')'],'FontSize',12,'FontWeight','bold' )
                    title([title_spec,LYSI_INFO{lysi},' : ',NOM_SONDE{sonde}],'FontSize',12,'FontWeight','bold' )
                    legend('Resistiviy calculated after inversion (E4D)','Resistiviy mesured by GS3 probes','Location','southeast');
                    
                    grid
                    ax = gca;
                    ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
                    ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
                    
                    %                 yyaxis right
                    %                 plot(ARROSAGE(:,1),ARROSAGE(:,2),'.--','LineWidth',2,'MarkerSize',10)
                    %                 ylabel({'Arrosage de la halde';'(Nb de passage par heure)'},'FontSize',14);
                    %                 yyaxis left
                    
                    % create smaller axes
                    for o=1
                        axes('Position',[.53 .55 .4 .4],'Visible','off')
                        box off
                        hold on
                        
                        % Mise en forme de la figure
                        daspect([1,1,1])
                        axis tight
                        ax = gca;
                        ax.FontSize = 13;
                        %view(0,0)
                        view(55,15)
                        light('Position',[40 -10 50],'Style','local')
                        camzoom(1.8)
                        
                        % Affichage des électrodes (approximation halde rectangulaire)
                        plot3(ELEC(:,1),ELEC(:,2),ELEC(:,3),'k.','MarkerSize',7.5)
                        hold on
                        plot3(Maillage3DSurface_2(:,1),Maillage3DSurface_2(:,2),Maillage3DSurface_2(:,3),'-k','LineWidth',0.875)
                        
                        plot3(GS3_location(:,2),GS3_location(:,3),GS3_location(:,4),'.r','MarkerSize',7.5)
                        plot3(GS3_location(:,2),GS3_location(:,3),GS3_location(:,4),'.r','MarkerSize',7.5)
                        
                        plot3(Barycentre(GS3_DATA_E4D(ind_ligne,5),2),Barycentre(GS3_DATA_E4D(ind_ligne,5),3),Barycentre(GS3_DATA_E4D(ind_ligne,5),4),'.g','MarkerSize',20)
                        
                        
                    end
                    
                    
                end
            end
        end
    end
    
    
    %% II - Superposition des données E4D et des données mesurées GS3
    actif=1;
    for o=1
        if actif==1
            p = get(gcf,'Position');
            set(0,'DefaultFigurePosition',p);
            close all
            load T_GS3.mat
            load GS3_DATA_mes.mat
            load T_GS3_RES_EAU.mat
            load GS3_DATA_EAU_mes.mat
            
            % Résistivité du sol
            %             GS3_DATA=GS3_DATA_E4D(:,1:5);
            %             for i=1:length(GS3_DATA_mes(:,1))
            %                 data_interp_gs3=interp1(T_GS3,GS3_DATA_mes(i,5:end),T_interp_2);
            %                 GS3_DATA(i,6:length(T_interp_2)+5)=data_interp_gs3';
            %             end
            %
            % Résistivité de l'Eau
            GS3_DATA_EAU=GS3_DATA_E4D(:,1:5);
            for i=1:length(GS3_DATA_EAU_mes(:,1))
                data_interp_gs3=interp1(T_GS3_RES_EAU,GS3_DATA_EAU_mes(i,5:end),T_interp_2);
                GS3_DATA_EAU(i,6:length(T_interp_2)+5)=data_interp_gs3';
            end
            
            
            pas_de_temps=1;
            format=formatOut1;
            
            
            % Matrices d'informations
            LYSI_INFO{1}=['Lysimètre 1'];
            LYSI_INFO{2}=['Lysimètre 2'];
            LYSI_INFO{3}=['Lysimètre 3'];
            LYSI_INFO{4}=['Lysimètre 4'];
            LYSI_INFO{5}=['Lysimètre 5'];
            LYSI_INFO{6}=['Lysimètre 6'];
            
            NOM_SONDE{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE{2}=['Ilmenite Haut, Z = 1.2 m'];
            NOM_SONDE{1}=['Ilmenite Bas, Z = 1.5 m'];
            NOM_SONDE{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE{7}=['Sable Base N2, Z = 7 m'];
            
            NOM_SONDE_an{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE_an{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE_an{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE_an{2}=['Anorthosite Haut, Z = 1.2 m'];
            NOM_SONDE_an{1}=['Anorthosite Bas, Z = 1.5 m'];
            NOM_SONDE_an{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE_an{7}=['Sable Base N2, Z = 7 m'];
            
            load    GS3_DATA_E4D_avec_lysi.mat
            load T_interp_2_avec_lysi.mat
            load    GS3_DATA_E4D_sans_lysi.mat
            load T_interp_2_sans_lysi.mat
            % FIGURES
            for lysi=5
                for sonde=2
                    
                    ind_ligne=(lysi-1)*7+sonde;
                    figure('Color', [ 1 1 1])
                    hold on
                    
                    %                     % Res mesurée E4D
                    %                     if time_lapse==1
                    %                         plot(T_interp_2(1:end-1,1),GS3_DATA_E4D(ind_ligne,6:end)','.-','LineWidth',4,'MarkerSize',10)
                    %                     else
                    %                         plot(T_interp_2(1,1),GS3_DATA_E4D(ind_ligne,6)','.','LineWidth',4,'MarkerSize',20)
                    %                     end
                    %                     %plot(T_interp_2_sans_lysi(1:end-1,1),GS3_DATA_E4D_sans_lysi(ind_ligne,6:end)','.-','LineWidth',4,'MarkerSize',10)
                    %                     ylabel({'Resistiviy calculated after inversion (E4D)';'(\Omega.m)'},'FontSize',14,'FontWeight','bold')
                    %
                    
                    %yyaxis right
                    % Res mesurée GS3
                    plot(T_interp_2(1:end,1),GS3_DATA(ind_ligne,6:end)','.-','LineWidth',4,'MarkerSize',10)
                    %plot(T_interp_2_sans_lysi(1:end-1,1),GS3_DATA_E4D_sans_lysi(ind_ligne,6:end)','.-','LineWidth',4,'MarkerSize',10)
                    ylabel({'Résistivité GS3';'(\Omega.m)'},'FontSize',14,'FontWeight','bold')
                    
                    yyaxis right
                    plot(T_interp_2(1:end,1),GS3_DATA_EAU(ind_ligne,6:end)','.-','LineWidth',4,'MarkerSize',10)
                    ylabel({'Résistivité GS3';'(\Omega.m)'},'FontSize',14,'FontWeight','bold')
                    
                    
                    % ylim([0 6000])
                    
                    hold on
                    
                    xlabel({'Elapsed time (dd/mm/yy)'},'FontSize',14,'FontWeight','bold')
                    if time_lapse==1
                        title_spec='COMPARAISON TIME-LAPSE : ';
                    else
                        title_spec='COMPARAISON STATIQUE : ';
                    end
                    % title([title_spec,LYSI_INFO{lysi},' : ',NOM_SONDE{sonde},' (rms = ',num2str(round(ERREUR)),')'],'FontSize',12,'FontWeight','bold' )
                    title([title_spec,LYSI_INFO{lysi},' : ',NOM_SONDE{sonde}],'FontSize',12,'FontWeight','bold' )
                    legend('Resistiviy calculated after inversion (E4D)','Resistiviy mesured by GS3 probes','Location','southeast');
                    
                    grid
                    ax = gca;
                    ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
                    ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
                    
                    %                 yyaxis right
                    %                 plot(ARROSAGE(:,1),ARROSAGE(:,2),'.--','LineWidth',2,'MarkerSize',10)
                    %                 ylabel({'Arrosage de la halde';'(Nb de passage par heure)'},'FontSize',14);
                    %                 yyaxis left
                    
                    % create smaller axes
                    for o=1
                        axes('Position',[.53 .55 .4 .4],'Visible','off')
                        box off
                        hold on
                        
                        % Mise en forme de la figure
                        daspect([1,1,1])
                        axis tight
                        ax = gca;
                        ax.FontSize = 13;
                        %view(0,0)
                        view(55,15)
                        light('Position',[40 -10 50],'Style','local')
                        camzoom(1.8)
                        
                        % Affichage des électrodes (approximation halde rectangulaire)
                        plot3(ELEC(:,1),ELEC(:,2),ELEC(:,3),'k.','MarkerSize',7.5)
                        hold on
                        plot3(Maillage3DSurface_2(:,1),Maillage3DSurface_2(:,2),Maillage3DSurface_2(:,3),'-k','LineWidth',0.875)
                        
                        plot3(GS3_location(:,2),GS3_location(:,3),GS3_location(:,4),'.r','MarkerSize',7.5)
                        plot3(GS3_location(:,2),GS3_location(:,3),GS3_location(:,4),'.r','MarkerSize',7.5)
                        
                        plot3(Barycentre(GS3_DATA_E4D(ind_ligne,5),2),Barycentre(GS3_DATA_E4D(ind_ligne,5),3),Barycentre(GS3_DATA_E4D(ind_ligne,5),4),'.g','MarkerSize',20)
                        
                        
                    end
                    
                    
                end
            end
        end
    end
    
    %% II - 4 SUPERPOSISTION #1
    actif=1;
    for o=1
        if actif==1
            p = get(gcf,'Position');
            set(0,'DefaultFigurePosition',p);
            close all
            load RES_APP_29.mat
            load RES_LYSI_1.mat
            
            pas_de_temps=1;
            format=formatOut1;
            
            lysi=1;
            sonde=6;
            ind_ligne=(lysi-1)*7+sonde;
            
            
            figure('Color', [ 1 1 1])
            hold on
            
            
            
            %
            % Res mesurée GS3
            plot(RES_LYSI_1(:,1),RES_LYSI_1(:,2),'.-','LineWidth',4,'MarkerSize',10)
            ylabel({'Soil resistivity';'GS3 (\Omega.m)'},'FontSize',14,'FontWeight','bold')
            ylim([21 52])
            
            
            % ylim([0 6000])
            
            hold on
            yyaxis right
            % Res apparente ABEM
            plot(RES_APP_29(:,1),RES_APP_29(:,2),'.','MarkerSize',30)
            plot(RES_APP_29(:,1),RES_APP_29(:,2),'.k','MarkerSize',15)
            ylabel({'Apparent soil resistivity';'3D ERT (\Omega.m)'},'FontSize',14,'FontWeight','bold')
            
            
            xlabel({'Elapsed time (dd/mm/yy)'},'FontSize',14,'FontWeight','bold')
            
            grid
            ax = gca;
            ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
            ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
            
            %                 yyaxis right
            %                 plot(ARROSAGE(:,1),ARROSAGE(:,2),'.--','LineWidth',2,'MarkerSize',10)
            %                 ylabel({'Arrosage de la halde';'(Nb de passage par heure)'},'FontSize',14);
            %                 yyaxis left
            
            % create smaller axes
            conf=29;
            for o=1
                
                
                CONFIGURATIONS_SELECT(1,1)=CONFIG_FOCUS{conf}(1,2);
                CONFIGURATIONS_SELECT(1,2)=CONFIG_FOCUS{conf}(1,3);
                CONFIGURATIONS_SELECT(1,3)=CONFIG_FOCUS{conf}(1,4);
                CONFIGURATIONS_SELECT(1,4)=CONFIG_FOCUS{conf}(1,5);
                
                
                clear SYNTHESE_VALUES_LIMITE
                C1_P1=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(1,1)&DUOS(:,2)==CONFIGURATIONS_SELECT(1,3)));
                C2_P1=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(1,2)&DUOS(:,2)==CONFIGURATIONS_SELECT(1,3)));
                C1_P2=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(1,1)&DUOS(:,2)==CONFIGURATIONS_SELECT(1,4)));
                C2_P2=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(1,2)&DUOS(:,2)==CONFIGURATIONS_SELECT(1,4)));
                SYNTHESE_VALUES_LIMITE(:,1)=abs(C1_P1-C2_P1-C1_P2+C2_P2);
                
                % Matrice de sensibilité pour le protocole limité
                SENSIBILITE_LIMITE=MAILLAGE;
                SENSIBILITE_LIMITE(:,4)=SYNTHESE_VALUES_LIMITE(:,1);
                
                
                garde=0;
                for j=1:length(SENSIBILITE_LIMITE(:,1))
                    if SENSIBILITE_LIMITE(j,3)<7.563+pente*(SENSIBILITE_LIMITE(j,1)-56.74)
                        garde(end+1,1)=j;
                    end
                end
                garde(1,:)=[];
                SENSIBILITE_LIMITE_2=SENSIBILITE_LIMITE(garde,:);
                
                
                % create smaller axes
                for o=1
                    axes('Position',[.35 .40 .7 .7],'Visible','off')
                    box off
                    hold on
                    
                    SENSIBILITE_DATA=SENSIBILITE_LIMITE_2;
                    SENSIBILITE_DATA(:,4)=log(SENSIBILITE_DATA(:,4));
                    % Interpolation
                    clearvars F;
                    F = scatteredInterpolant(SENSIBILITE_DATA(:,1),SENSIBILITE_DATA(:,2),SENSIBILITE_DATA(:,3),SENSIBILITE_DATA(:,4),'natural');
                    vq = F(X,Y,Z);
                    ValAffichee = vq;
                    
                    % Suppression des données au dessus de la surface
                    for xi=1:length(X(1,:,1))
                        for yi=1:length(X(:,1,1))
                            for zi=1:length(X(1,1,:))
                                if Z(yi,xi,zi)>7.563+pente*(X(yi,xi,zi)-56.74)+0.5
                                    ValAffichee(yi,xi,zi)=NaN;
                                end
                            end
                        end
                    end
                    
                    % Mise en forme de la figure
                    daspect([1,1,1])
                    axis tight
                    ax = gca;
                    ax.FontSize = 13;
                    %view(0,0)
                    view(55,15)
                    light('Position',[40 -10 50],'Style','local')
                    camzoom(1.8)
                    camproj('perspective')
                    colormap (flipud(hot(10)));
                    cmap = colormap;
                    
                    
                    
                    % Affichage des volumes (UNE seule valeur de coupure)
                    Valeur=[-7;-5];
                    V_Max=-5;
                    V_Min=-10;
                    Valeur_Indice = round((Valeur-V_Min)*10/(V_Max-V_Min));
                    for ki=1:length(Valeur_Indice(:,1))
                        p1=patch(isocaps(X,Y,Z,ValAffichee,Valeur(ki,1),'enclose','above'),...
                            'FaceColor','interp','EdgeColor','none','FaceAlpha',0.7);
                        p1 = patch(isosurface(X,Y,Z,ValAffichee,Valeur(ki,1),'enclose','above'),...
                            'FaceColor',cmap(Valeur_Indice(ki,1),:),'EdgeColor','none','FaceAlpha',0.7);
                    end
                    
                    
                    % Affichage des électrodes (approximation halde rectangulaire)
                    for j=1:length(ELEC(:,1))
                        plot3(ELEC(j,1),ELEC(j,2),ELEC(j,3),'k.','MarkerSize',7.5)
                    end
                    for j=1:length(ELEC_FAUSSES(:,1))
                        plot3(ELEC(ELEC_FAUSSES(j,1),1),ELEC(ELEC_FAUSSES(j,1),2),ELEC(ELEC_FAUSSES(j,1),3),'.r','MarkerSize',7.5)
                    end
                    for j=1:length(ELEC_MAUVAISES(:,1))
                        plot3(ELEC(ELEC_MAUVAISES(j,1),1),ELEC(ELEC_MAUVAISES(j,1),2),ELEC(ELEC_MAUVAISES(j,1),3),'.m','MarkerSize',7.5)
                    end
                    
                    % Limites de la halde
                    xlim([20 110]);
                    %                 ylim([21 31]);
                    %                 zlim([1 9]);
                    plot3(Maillage3DSurface_2(:,1),Maillage3DSurface_2(:,2),Maillage3DSurface_2(:,3),'-k','LineWidth',0.875)
                    %axes('Color','none','XColor','none');
                    
                end
                
                
                
                
                
                
                plot3(Barycentre(GS3_DATA_E4D(ind_ligne,5),2),Barycentre(GS3_DATA_E4D(ind_ligne,5),3),Barycentre(GS3_DATA_E4D(ind_ligne,5),4),'.b','MarkerSize',30)
                
                
            end
            
            
        end
    end
    
    %% II - 4 SUPERPOSISTION #2
    actif=1;
    for o=1
        if actif==1
            p = get(gcf,'Position');
            set(0,'DefaultFigurePosition',p);
            close all
            load RES_APP_616.mat
            load RES_LYSI_6.mat
            
            pas_de_temps=1;
            format=formatOut1;
            
            
            lysi=6;
            sonde=6;
            ind_ligne=(lysi-1)*7+sonde;
            
            % Matrices d'informations
            LYSI_INFO{1}=['Lysimètre 1'];
            LYSI_INFO{2}=['Lysimètre 2'];
            LYSI_INFO{3}=['Lysimètre 3'];
            LYSI_INFO{4}=['Lysimètre 4'];
            LYSI_INFO{5}=['Lysimètre 5'];
            LYSI_INFO{6}=['Lysimètre 6'];
            
            NOM_SONDE{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE{2}=['Ilmenite Haut, Z = 1.2 m'];
            NOM_SONDE{1}=['Ilmenite Bas, Z = 1.5 m'];
            NOM_SONDE{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE{7}=['Sable Base N2, Z = 7 m'];
            
            NOM_SONDE_an{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE_an{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE_an{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE_an{2}=['Anorthosite Haut, Z = 1.2 m'];
            NOM_SONDE_an{1}=['Anorthosite Bas, Z = 1.5 m'];
            NOM_SONDE_an{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE_an{7}=['Sable Base N2, Z = 7 m'];
            
            load    GS3_DATA_E4D_avec_lysi.mat
            load T_interp_2_avec_lysi.mat
            load    GS3_DATA_E4D_sans_lysi.mat
            load T_interp_2_sans_lysi.mat
            % FIGURES
            
            figure('Color', [ 1 1 1])
            hold on
            
            %
            % Res mesurée GS3
            plot(RES_LYSI_6(:,1),RES_LYSI_6(:,2),'.-','LineWidth',4,'MarkerSize',10)
            ylabel({'Soil resistivity';'GS3 (\Omega.m)'},'FontSize',14,'FontWeight','bold')
            % ylim([21 52])
            
            
            % ylim([0 6000])
            
            hold on
            yyaxis right
            % Res apparente ABEM
            plot(RES_APP_616(:,1),RES_APP_616(:,2),'.','MarkerSize',30)
            plot(RES_APP_616(:,1),RES_APP_616(:,2),'.k','MarkerSize',15)
            ylabel({'Apparent soil resistivity';'3D ERT (\Omega.m)'},'FontSize',14,'FontWeight','bold')
            ylim([1550 2600])
            
            xlabel({'Elapsed time (dd/mm/yy)'},'FontSize',14,'FontWeight','bold')
            
            grid
            ax = gca;
            ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
            ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
            
            %                 yyaxis right
            %                 plot(ARROSAGE(:,1),ARROSAGE(:,2),'.--','LineWidth',2,'MarkerSize',10)
            %                 ylabel({'Arrosage de la halde';'(Nb de passage par heure)'},'FontSize',14);
            %                 yyaxis left
            
            % create smaller axes
            conf=616;
            for o=1
                
                
                CONFIGURATIONS_SELECT(1,1)=CONFIG_FOCUS{conf}(1,2);
                CONFIGURATIONS_SELECT(1,2)=CONFIG_FOCUS{conf}(1,3);
                CONFIGURATIONS_SELECT(1,3)=CONFIG_FOCUS{conf}(1,4);
                CONFIGURATIONS_SELECT(1,4)=CONFIG_FOCUS{conf}(1,5);
                
                
                clear SYNTHESE_VALUES_LIMITE
                C1_P1=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(1,1)&DUOS(:,2)==CONFIGURATIONS_SELECT(1,3)));
                C2_P1=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(1,2)&DUOS(:,2)==CONFIGURATIONS_SELECT(1,3)));
                C1_P2=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(1,1)&DUOS(:,2)==CONFIGURATIONS_SELECT(1,4)));
                C2_P2=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(1,2)&DUOS(:,2)==CONFIGURATIONS_SELECT(1,4)));
                SYNTHESE_VALUES_LIMITE(:,1)=abs(C1_P1-C2_P1-C1_P2+C2_P2);
                
                % Matrice de sensibilité pour le protocole limité
                SENSIBILITE_LIMITE=MAILLAGE;
                SENSIBILITE_LIMITE(:,4)=SYNTHESE_VALUES_LIMITE(:,1);
                
                
                garde=0;
                for j=1:length(SENSIBILITE_LIMITE(:,1))
                    if SENSIBILITE_LIMITE(j,3)<7.563+pente*(SENSIBILITE_LIMITE(j,1)-56.74)
                        garde(end+1,1)=j;
                    end
                end
                garde(1,:)=[];
                SENSIBILITE_LIMITE_2=SENSIBILITE_LIMITE(garde,:);
                
                
                % create smaller axes
                for o=1
                    axes('Position',[.35 .40 .7 .7],'Visible','off')
                    box off
                    hold on
                    
                    SENSIBILITE_DATA=SENSIBILITE_LIMITE_2;
                    SENSIBILITE_DATA(:,4)=log(SENSIBILITE_DATA(:,4));
                    % Interpolation
                    clearvars F;
                    F = scatteredInterpolant(SENSIBILITE_DATA(:,1),SENSIBILITE_DATA(:,2),SENSIBILITE_DATA(:,3),SENSIBILITE_DATA(:,4),'natural');
                    vq = F(X,Y,Z);
                    ValAffichee = vq;
                    
                    % Suppression des données au dessus de la surface
                    for xi=1:length(X(1,:,1))
                        for yi=1:length(X(:,1,1))
                            for zi=1:length(X(1,1,:))
                                if Z(yi,xi,zi)>7.563+pente*(X(yi,xi,zi)-56.74)+0.5
                                    ValAffichee(yi,xi,zi)=NaN;
                                end
                            end
                        end
                    end
                    
                    % Mise en forme de la figure
                    daspect([1,1,1])
                    axis tight
                    ax = gca;
                    ax.FontSize = 13;
                    %view(0,0)
                    view(55,15)
                    light('Position',[40 -10 50],'Style','local')
                    camzoom(1.8)
                    camproj('perspective')
                    colormap (flipud(hot(10)));
                    cmap = colormap;
                    
                    
                    
                    % Affichage des volumes (UNE seule valeur de coupure)
                    Valeur=[-7;-5];
                    V_Max=-5;
                    V_Min=-10;
                    Valeur_Indice = round((Valeur-V_Min)*10/(V_Max-V_Min));
                    for ki=1:length(Valeur_Indice(:,1))
                        p1=patch(isocaps(X,Y,Z,ValAffichee,Valeur(ki,1),'enclose','above'),...
                            'FaceColor','interp','EdgeColor','none','FaceAlpha',0.7);
                        p1 = patch(isosurface(X,Y,Z,ValAffichee,Valeur(ki,1),'enclose','above'),...
                            'FaceColor',cmap(Valeur_Indice(ki,1),:),'EdgeColor','none','FaceAlpha',0.7);
                    end
                    
                    
                    % Affichage des électrodes (approximation halde rectangulaire)
                    for j=1:length(ELEC(:,1))
                        plot3(ELEC(j,1),ELEC(j,2),ELEC(j,3),'k.','MarkerSize',7.5)
                    end
                    for j=1:length(ELEC_FAUSSES(:,1))
                        plot3(ELEC(ELEC_FAUSSES(j,1),1),ELEC(ELEC_FAUSSES(j,1),2),ELEC(ELEC_FAUSSES(j,1),3),'.r','MarkerSize',7.5)
                    end
                    for j=1:length(ELEC_MAUVAISES(:,1))
                        plot3(ELEC(ELEC_MAUVAISES(j,1),1),ELEC(ELEC_MAUVAISES(j,1),2),ELEC(ELEC_MAUVAISES(j,1),3),'.m','MarkerSize',7.5)
                    end
                    
                    % Limites de la halde
                    xlim([20 110]);
                    %                 ylim([21 31]);
                    %                 zlim([1 9]);
                    plot3(Maillage3DSurface_2(:,1),Maillage3DSurface_2(:,2),Maillage3DSurface_2(:,3),'-k','LineWidth',0.875)
                    %axes('Color','none','XColor','none');
                    
                end
                
                
                
                
                
                
                plot3(Barycentre(GS3_DATA_E4D(ind_ligne,5),2),Barycentre(GS3_DATA_E4D(ind_ligne,5),3),Barycentre(GS3_DATA_E4D(ind_ligne,5),4),'.b','MarkerSize',30)
                
                
            end
            
            
        end
    end
    
    %% II - 4 SUPERPOSISTION #3
    actif=1;
    for o=1
        if actif==1
            p = get(gcf,'Position');
            set(0,'DefaultFigurePosition',p);
            close all
            load RES_APP_872.mat
            load RES_LYSI_4_SAND.mat
            
            pas_de_temps=1;
            format=formatOut1;
            
            
            lysi=4;
            sonde=5;
            ind_ligne=(lysi-1)*7+sonde;
            
            % Matrices d'informations
            LYSI_INFO{1}=['Lysimètre 1'];
            LYSI_INFO{2}=['Lysimètre 2'];
            LYSI_INFO{3}=['Lysimètre 3'];
            LYSI_INFO{4}=['Lysimètre 4'];
            LYSI_INFO{5}=['Lysimètre 5'];
            LYSI_INFO{6}=['Lysimètre 6'];
            
            NOM_SONDE{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE{2}=['Ilmenite Haut, Z = 1.2 m'];
            NOM_SONDE{1}=['Ilmenite Bas, Z = 1.5 m'];
            NOM_SONDE{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE{7}=['Sable Base N2, Z = 7 m'];
            
            NOM_SONDE_an{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE_an{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE_an{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE_an{2}=['Anorthosite Haut, Z = 1.2 m'];
            NOM_SONDE_an{1}=['Anorthosite Bas, Z = 1.5 m'];
            NOM_SONDE_an{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE_an{7}=['Sable Base N2, Z = 7 m'];
            
            load    GS3_DATA_E4D_avec_lysi.mat
            load T_interp_2_avec_lysi.mat
            load    GS3_DATA_E4D_sans_lysi.mat
            load T_interp_2_sans_lysi.mat
            % FIGURES
            
            figure('Color', [ 1 1 1])
            hold on
            
            %
            % Res mesurée GS3
            plot(RES_LYSI_4_SAND(:,1),RES_LYSI_4_SAND(:,2),'.-','LineWidth',4,'MarkerSize',10)
            ylabel({'Soil resistivity';'GS3 (\Omega.m)'},'FontSize',14,'FontWeight','bold')
            % ylim([21 52])
            
            
            ylim([0 2500])
            
            hold on
            yyaxis right
            % Res apparente ABEM
            plot(RES_APP_872(:,1),abs(RES_APP_872(:,2)),'.','MarkerSize',30)
            plot(RES_APP_872(:,1),abs(RES_APP_872(:,2)),'.k','MarkerSize',15)
            ylabel({'Apparent soil resistivity';'3D ERT (\Omega.m)'},'FontSize',14,'FontWeight','bold')
            %ylim([0 1750])
            
            xlabel({'Elapsed time (dd/mm/yy)'},'FontSize',14,'FontWeight','bold')
            
            grid
            ax = gca;
            ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
            ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
            
            %                 yyaxis right
            %                 plot(ARROSAGE(:,1),ARROSAGE(:,2),'.--','LineWidth',2,'MarkerSize',10)
            %                 ylabel({'Arrosage de la halde';'(Nb de passage par heure)'},'FontSize',14);
            %                 yyaxis left
            
            % create smaller axes
            conf=872;
            for o=1
                
                
                CONFIGURATIONS_SELECT(1,1)=CONFIG_FOCUS{conf}(1,2);
                CONFIGURATIONS_SELECT(1,2)=CONFIG_FOCUS{conf}(1,3);
                CONFIGURATIONS_SELECT(1,3)=CONFIG_FOCUS{conf}(1,4);
                CONFIGURATIONS_SELECT(1,4)=CONFIG_FOCUS{conf}(1,5);
                
                
                clear SYNTHESE_VALUES_LIMITE
                C1_P1=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(1,1)&DUOS(:,2)==CONFIGURATIONS_SELECT(1,3)));
                C2_P1=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(1,2)&DUOS(:,2)==CONFIGURATIONS_SELECT(1,3)));
                C1_P2=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(1,1)&DUOS(:,2)==CONFIGURATIONS_SELECT(1,4)));
                C2_P2=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(1,2)&DUOS(:,2)==CONFIGURATIONS_SELECT(1,4)));
                SYNTHESE_VALUES_LIMITE(:,1)=abs(C1_P1-C2_P1-C1_P2+C2_P2);
                
                % Matrice de sensibilité pour le protocole limité
                SENSIBILITE_LIMITE=MAILLAGE;
                SENSIBILITE_LIMITE(:,4)=SYNTHESE_VALUES_LIMITE(:,1);
                
                
                garde=0;
                for j=1:length(SENSIBILITE_LIMITE(:,1))
                    if SENSIBILITE_LIMITE(j,3)<7.563+pente*(SENSIBILITE_LIMITE(j,1)-56.74)
                        garde(end+1,1)=j;
                    end
                end
                garde(1,:)=[];
                SENSIBILITE_LIMITE_2=SENSIBILITE_LIMITE(garde,:);
                
                
                % create smaller axes
                for o=1
                    axes('Position',[.35 .40 .7 .7],'Visible','off')
                    box off
                    hold on
                    
                    SENSIBILITE_DATA=SENSIBILITE_LIMITE_2;
                    SENSIBILITE_DATA(:,4)=log(SENSIBILITE_DATA(:,4));
                    % Interpolation
                    clearvars F;
                    F = scatteredInterpolant(SENSIBILITE_DATA(:,1),SENSIBILITE_DATA(:,2),SENSIBILITE_DATA(:,3),SENSIBILITE_DATA(:,4),'natural');
                    vq = F(X,Y,Z);
                    ValAffichee = vq;
                    
                    % Suppression des données au dessus de la surface
                    for xi=1:length(X(1,:,1))
                        for yi=1:length(X(:,1,1))
                            for zi=1:length(X(1,1,:))
                                if Z(yi,xi,zi)>7.563+pente*(X(yi,xi,zi)-56.74)+0.5
                                    ValAffichee(yi,xi,zi)=NaN;
                                end
                            end
                        end
                    end
                    
                    % Mise en forme de la figure
                    daspect([1,1,1])
                    axis tight
                    ax = gca;
                    ax.FontSize = 13;
                    %view(0,0)
                    view(55,15)
                    light('Position',[40 -10 50],'Style','local')
                    camzoom(1.8)
                    camproj('perspective')
                    colormap (flipud(hot(10)));
                    cmap = colormap;
                    
                    
                    
                    % Affichage des volumes (UNE seule valeur de coupure)
                    Valeur=[-7;-5];
                    V_Max=-5;
                    V_Min=-10;
                    Valeur_Indice = round((Valeur-V_Min)*10/(V_Max-V_Min));
                    for ki=1:length(Valeur_Indice(:,1))
                        p1=patch(isocaps(X,Y,Z,ValAffichee,Valeur(ki,1),'enclose','above'),...
                            'FaceColor','interp','EdgeColor','none','FaceAlpha',0.7);
                        p1 = patch(isosurface(X,Y,Z,ValAffichee,Valeur(ki,1),'enclose','above'),...
                            'FaceColor',cmap(Valeur_Indice(ki,1),:),'EdgeColor','none','FaceAlpha',0.7);
                    end
                    
                    
                    % Affichage des électrodes (approximation halde rectangulaire)
                    for j=1:length(ELEC(:,1))
                        plot3(ELEC(j,1),ELEC(j,2),ELEC(j,3),'k.','MarkerSize',7.5)
                    end
                    for j=1:length(ELEC_FAUSSES(:,1))
                        plot3(ELEC(ELEC_FAUSSES(j,1),1),ELEC(ELEC_FAUSSES(j,1),2),ELEC(ELEC_FAUSSES(j,1),3),'.r','MarkerSize',7.5)
                    end
                    for j=1:length(ELEC_MAUVAISES(:,1))
                        plot3(ELEC(ELEC_MAUVAISES(j,1),1),ELEC(ELEC_MAUVAISES(j,1),2),ELEC(ELEC_MAUVAISES(j,1),3),'.m','MarkerSize',7.5)
                    end
                    
                    % Limites de la halde
                    xlim([20 110]);
                    %                 ylim([21 31]);
                    %                 zlim([1 9]);
                    plot3(Maillage3DSurface_2(:,1),Maillage3DSurface_2(:,2),Maillage3DSurface_2(:,3),'-k','LineWidth',0.875)
                    %axes('Color','none','XColor','none');
                    
                end
                
                
                
                
                
                
                plot3(Barycentre(GS3_DATA_E4D(ind_ligne,5),2),Barycentre(GS3_DATA_E4D(ind_ligne,5),3),Barycentre(GS3_DATA_E4D(ind_ligne,5),4),'.b','MarkerSize',30)
                
                
            end
            
            
        end
    end
    
    %% II - 4 Superposition des données E4D et des données mesurées GS3
    actif=1;
    for o=1
        if actif==1
            p = get(gcf,'Position');
            set(0,'DefaultFigurePosition',p);
            close all
            load RES_APP_29.mat
            load RES_LYSI_1.mat
            
            % Résistivité du sol
            GS3_DATA=GS3_DATA_E4D(:,1:5);
            for i=1:length(GS3_DATA_mes(:,1))
                data_interp_gs3=interp1(T_GS3,GS3_DATA_mes(i,5:end),T_interp_2);
                GS3_DATA(i,6:length(T_interp_2)+5)=data_interp_gs3';
            end
            
            % Résistivité de l'Eau
            GS3_DATA_EAU=GS3_DATA_E4D(:,1:5);
            for i=1:length(GS3_DATA_EAU_mes(:,1))
                data_interp_gs3=interp1(T_GS3_RES_EAU,GS3_DATA_EAU_mes(i,5:end),T_interp_2);
                GS3_DATA_EAU(i,6:length(T_interp_2)+5)=data_interp_gs3';
            end
            
            
            pas_de_temps=1;
            format=formatOut1;
            
            
            % Matrices d'informations
            LYSI_INFO{1}=['Lysimètre 1'];
            LYSI_INFO{2}=['Lysimètre 2'];
            LYSI_INFO{3}=['Lysimètre 3'];
            LYSI_INFO{4}=['Lysimètre 4'];
            LYSI_INFO{5}=['Lysimètre 5'];
            LYSI_INFO{6}=['Lysimètre 6'];
            
            NOM_SONDE{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE{2}=['Ilmenite Haut, Z = 1.2 m'];
            NOM_SONDE{1}=['Ilmenite Bas, Z = 1.5 m'];
            NOM_SONDE{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE{7}=['Sable Base N2, Z = 7 m'];
            
            NOM_SONDE_an{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE_an{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE_an{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE_an{2}=['Anorthosite Haut, Z = 1.2 m'];
            NOM_SONDE_an{1}=['Anorthosite Bas, Z = 1.5 m'];
            NOM_SONDE_an{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE_an{7}=['Sable Base N2, Z = 7 m'];
            
            load    GS3_DATA_E4D_avec_lysi.mat
            load T_interp_2_avec_lysi.mat
            load    GS3_DATA_E4D_sans_lysi.mat
            load T_interp_2_sans_lysi.mat
            % FIGURES
            
            figure('Color', [ 1 1 1])
            hold on
            
            %
            % Res mesurée GS3
            plot(RES_LYSI_1(:,1),RES_LYSI_1(:,2),'.-','LineWidth',4,'MarkerSize',10)
            ylabel({'Soil resistivity';'GS3 (\Omega.m)'},'FontSize',14,'FontWeight','bold')
            ylim([21 52])
            
            
            % ylim([0 6000])
            
            hold on
            yyaxis right
            % Res apparente ABEM
            plot(RES_APP_29(:,1),RES_APP_29(:,2),'.','MarkerSize',30)
            ylabel({'Apparent soil resistivity';'3D ERT (\Omega.m)'},'FontSize',14,'FontWeight','bold')
            
            
            xlabel({'Elapsed time (dd/mm/yy)'},'FontSize',14,'FontWeight','bold')
            
            grid
            ax = gca;
            ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
            ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
            
            %                 yyaxis right
            %                 plot(ARROSAGE(:,1),ARROSAGE(:,2),'.--','LineWidth',2,'MarkerSize',10)
            %                 ylabel({'Arrosage de la halde';'(Nb de passage par heure)'},'FontSize',14);
            %                 yyaxis left
            
            % create smaller axes
            for o=1
                axes('Position',[.35 .40 .7 .7],'Visible','off')
                box off
                hold on
                
                % Mise en forme de la figure
                daspect([1,1,1])
                axis tight
                ax = gca;
                ax.FontSize = 13;
                %view(0,0)
                view(55,15)
                light('Position',[40 -10 50],'Style','local')
                camzoom(1.8)
                
                % Affichage des électrodes (approximation halde rectangulaire)
                plot3(ELEC(:,1),ELEC(:,2),ELEC(:,3),'k.','MarkerSize',7.5)
                hold on
                plot3(Maillage3DSurface_2(:,1),Maillage3DSurface_2(:,2),Maillage3DSurface_2(:,3),'-k','LineWidth',0.875)
                
                plot3(GS3_location(:,2),GS3_location(:,3),GS3_location(:,4),'.r','MarkerSize',7.5)
                plot3(GS3_location(:,2),GS3_location(:,3),GS3_location(:,4),'.r','MarkerSize',7.5)
                
                plot3(Barycentre(GS3_DATA_E4D(ind_ligne,5),2),Barycentre(GS3_DATA_E4D(ind_ligne,5),3),Barycentre(GS3_DATA_E4D(ind_ligne,5),4),'.b','MarkerSize',30)
                
                
            end
            
            
        end
    end
    
    %% II - FIGURE 9 PART 1
    actif=1;
    for o=1
        if actif==1
            p = get(gcf,'Position');
            set(0,'DefaultFigurePosition',p);
            close all
            load T_GS3.mat
            load GS3_DATA_mes.mat
            load T_GS3_RES_EAU.mat
            load GS3_DATA_EAU_mes.mat
            
            % Résistivité du sol
            GS3_DATA=GS3_DATA_E4D(:,1:5);
            for i=1:length(GS3_DATA_mes(:,1))
                data_interp_gs3=interp1(T_GS3,GS3_DATA_mes(i,5:end),T_interp_2);
                GS3_DATA(i,6:length(T_interp_2)+5)=data_interp_gs3';
            end
            
            % Résistivité de l'Eau
            GS3_DATA_EAU=GS3_DATA_E4D(:,1:5);
            for i=1:length(GS3_DATA_EAU_mes(:,1))
                data_interp_gs3=interp1(T_GS3_RES_EAU,GS3_DATA_EAU_mes(i,5:end),T_interp_2);
                GS3_DATA_EAU(i,6:length(T_interp_2)+5)=data_interp_gs3';
            end
            
            
            pas_de_temps=1;
            format=formatOut1;
            
            
            % Matrices d'informations
            LYSI_INFO{1}=['Lysimètre 1'];
            LYSI_INFO{2}=['Lysimètre 2'];
            LYSI_INFO{3}=['Lysimètre 3'];
            LYSI_INFO{4}=['Lysimètre 4'];
            LYSI_INFO{5}=['Lysimètre 5'];
            LYSI_INFO{6}=['Lysimètre 6'];
            
            NOM_SONDE{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE{2}=['Ilmenite Haut, Z = 1.2 m'];
            NOM_SONDE{1}=['Ilmenite Bas, Z = 1.5 m'];
            NOM_SONDE{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE{7}=['Sable Base N2, Z = 7 m'];
            
            NOM_SONDE_an{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE_an{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE_an{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE_an{2}=['Anorthosite Haut, Z = 1.2 m'];
            NOM_SONDE_an{1}=['Anorthosite Bas, Z = 1.5 m'];
            NOM_SONDE_an{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE_an{7}=['Sable Base N2, Z = 7 m'];
            
            load    GS3_DATA_E4D_avec_lysi.mat
            load T_interp_2_avec_lysi.mat
            load    GS3_DATA_E4D_sans_lysi.mat
            load T_interp_2_sans_lysi.mat
            % FIGURES
            figure('Color', [ 1 1 1])
            hold on
            for lysi=4
                for sonde=4
                    
                    ind_ligne=(lysi-1)*7+sonde;
                    
                    
                    
                    %                    % TEMP sable haut lys 4
                    %             TEMP_DATA_2=interp1(TEMP_DATA(:,1)+1.5  ,TEMP_DATA(:,2),T_interp_2);
                    %               % Res mesurée GS3
                    %                     plot(T_interp_2,TEMP_DATA_2(:,1),'.-g','LineWidth',3,'MarkerSize',10)
                    %                     ylabel({'Temperature';'(GS3 sensors) (°C)'},'FontSize',14,'FontWeight','bold')
                    
                    
                    % Res mesurée GS3
                    plot(T_interp_2(1:end,1),GS3_DATA_EAU(ind_ligne,6:end)','.-','LineWidth',4,'MarkerSize',10)
                    ylabel({'Water Electrical Resistivity';'(GS3 sensors) (\Omega.m)'},'FontSize',14,'FontWeight','bold')
                end
            end
            % Teneur en eau sable haut lys 4
            load VWC_DATA
            VWC_DATA_2=interp1(VWC_DATA(:,1)-T_CORR,VWC_DATA(:,2),T_interp_2);
            
            %ylim([-1000 2500])
            yyaxis right
            plot(T_interp_2,VWC_DATA_2(:,1)-0.16,'.-','LineWidth',4,'MarkerSize',10)
            hold on
            %             %ylim([0.22 0.5])
            ylabel({'Volumetric Water Content';'(GS3 sensors) (%)'},'FontSize',14,'FontWeight','bold')
            
            % ylim([0 6000])
            
            hold on
            
            xlabel({'Elapsed time (dd/mm/yy)'},'FontSize',14,'FontWeight','bold')
            if time_lapse==1
                title_spec='COMPARAISON TIME-LAPSE : ';
            else
                title_spec='COMPARAISON STATIQUE : ';
            end
            
            grid
            ax = gca;
            ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
            ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
            
            %             for o=1
            %                 axes('Position',[.44 .45 .45 .45])
            %
            %                 hold on
            %                 hold on
            %                 for lysi=4
            %                     for sonde=4
            %
            %                         ind_ligne=(lysi-1)*7+sonde;
            %
            %
            %
            %                         % TEMP sable haut lys 4
            %                         TEMP_DATA_2=interp1(TEMP_DATA(:,1)+1.5  ,TEMP_DATA(:,2),T_interp_2);
            %                         % Res mesurée GS3
            %                         plot(T_interp_2,TEMP_DATA_2(:,1),'.-g','LineWidth',3,'MarkerSize',10)
            %                         ylabel({'Temperature';'(GS3 sensors) (°C)'},'FontSize',14,'FontWeight','bold')
            %
            %
            %                         %                     % Res mesurée GS3
            %                         %                     plot(T_interp_2(1:end,1),GS3_DATA_EAU(ind_ligne,6:end)','.-','LineWidth',4,'MarkerSize',10)
            %                         %                     ylabel({'Water Electrical Resistivity';'(GS3 sensors) (\Omega.m)'},'FontSize',14,'FontWeight','bold')
            %                     end
            %                 end
            %                 % Teneur en eau sable haut lys 4
            %                 %                         VWC_DATA_2=interp1(VWC_DATA(:,1)-T_CORR,VWC_DATA(:,2),T_interp_2);
            %                 %
            %                 %             %ylim([-1000 2500])
            %                 %                            yyaxis right
            %                 %                         plot(T_interp_2,VWC_DATA_2(:,1)-0.16,'.-','LineWidth',4,'MarkerSize',10)
            %                 %                         hold on
            %                 %             %             %ylim([0.22 0.5])
            %                 %                         ylabel({'Volumetric Water Content';'(GS3 sensors) (%)'},'FontSize',14,'FontWeight','bold')
            %                 %
            %                 % ylim([0 6000])
            %
            %                 hold on
            %                 if time_lapse==1
            %                     title_spec='COMPARAISON TIME-LAPSE : ';
            %                 else
            %                     title_spec='COMPARAISON STATIQUE : ';
            %                 end
            %
            %                 grid
            %                 ax = gca;
            %                 ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
            %                 ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
            %             end
        end
    end
    
    %% II - FIGURE 9 PART 2
    actif=0;
    for o=1
        if actif==1
            p = get(gcf,'Position');
            set(0,'DefaultFigurePosition',p);
            close all
            load T_GS3.mat
            load GS3_DATA_mes.mat
            load T_GS3_RES_EAU.mat
            load GS3_DATA_EAU_mes.mat
            
            % Résistivité du sol
            GS3_DATA=GS3_DATA_E4D(:,1:5);
            for i=1:length(GS3_DATA_mes(:,1))
                data_interp_gs3=interp1(T_GS3,GS3_DATA_mes(i,5:end),T_interp_2);
                GS3_DATA(i,6:length(T_interp_2)+5)=data_interp_gs3';
            end
            
            % Résistivité de l'Eau
            GS3_DATA_EAU=GS3_DATA_E4D(:,1:5);
            for i=1:length(GS3_DATA_EAU_mes(:,1))
                data_interp_gs3=interp1(T_GS3_RES_EAU,GS3_DATA_EAU_mes(i,5:end),T_interp_2);
                GS3_DATA_EAU(i,6:length(T_interp_2)+5)=data_interp_gs3';
            end
            
            
            pas_de_temps=1;
            format=formatOut1;
            
            
            % Matrices d'informations
            LYSI_INFO{1}=['Lysimètre 1'];
            LYSI_INFO{2}=['Lysimètre 2'];
            LYSI_INFO{3}=['Lysimètre 3'];
            LYSI_INFO{4}=['Lysimètre 4'];
            LYSI_INFO{5}=['Lysimètre 5'];
            LYSI_INFO{6}=['Lysimètre 6'];
            
            NOM_SONDE{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE{2}=['Ilmenite Haut, Z = 1.2 m'];
            NOM_SONDE{1}=['Ilmenite Bas, Z = 1.5 m'];
            NOM_SONDE{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE{7}=['Sable Base N2, Z = 7 m'];
            
            NOM_SONDE_an{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE_an{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE_an{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE_an{2}=['Anorthosite Haut, Z = 1.2 m'];
            NOM_SONDE_an{1}=['Anorthosite Bas, Z = 1.5 m'];
            NOM_SONDE_an{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE_an{7}=['Sable Base N2, Z = 7 m'];
            
            load    GS3_DATA_E4D_avec_lysi.mat
            load T_interp_2_avec_lysi.mat
            load    GS3_DATA_E4D_sans_lysi.mat
            load T_interp_2_sans_lysi.mat
            % FIGURES
            figure('Color', [ 1 1 1])
            hold on
            for lysi=4
                for sonde=4
                    
                    ind_ligne=(lysi-1)*7+sonde;
                    
                    
                    
                    % TEMP sable haut lys 4
                    TEMP_DATA_2=interp1(TEMP_DATA(:,1)+1.5  ,TEMP_DATA(:,2),T_interp_2);
                    % Res mesurée GS3
                    plot(T_interp_2,TEMP_DATA_2(:,1),'.-g','LineWidth',3,'MarkerSize',10)
                    ylabel({'Temperature';'(GS3 sensors) (°C)'},'FontSize',14,'FontWeight','bold')
                    
                    
                    %                     % Res mesurée GS3
                    %                     plot(T_interp_2(1:end,1),GS3_DATA_EAU(ind_ligne,6:end)','.-','LineWidth',4,'MarkerSize',10)
                    %                     ylabel({'Water Electrical Resistivity';'(GS3 sensors) (\Omega.m)'},'FontSize',14,'FontWeight','bold')
                end
            end
            % Teneur en eau sable haut lys 4
            %                         VWC_DATA_2=interp1(VWC_DATA(:,1)-T_CORR,VWC_DATA(:,2),T_interp_2);
            %
            %             %ylim([-1000 2500])
            %                            yyaxis right
            %                         plot(T_interp_2,VWC_DATA_2(:,1)-0.16,'.-','LineWidth',4,'MarkerSize',10)
            %                         hold on
            %             %             %ylim([0.22 0.5])
            %                         ylabel({'Volumetric Water Content';'(GS3 sensors) (%)'},'FontSize',14,'FontWeight','bold')
            %
            % ylim([0 6000])
            
            hold on
            
            xlabel({'Elapsed time (dd/mm/yy)'},'FontSize',14,'FontWeight','bold')
            if time_lapse==1
                title_spec='COMPARAISON TIME-LAPSE : ';
            else
                title_spec='COMPARAISON STATIQUE : ';
            end
            
            grid
            ax = gca;
            ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
            ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
            
        end
    end
    
    %% II - FIGURE SAGEEP
    actif=1;
    for o=1
        if actif==1
            p = get(gcf,'Position');
            set(0,'DefaultFigurePosition',p);
            close all
            load T_GS3.mat
            load GS3_DATA_mes.mat
            load T_GS3_RES_EAU.mat
            load GS3_DATA_EAU_mes.mat
            
            % Résistivité du sol
            GS3_DATA=GS3_DATA_E4D(:,1:5);
            for i=1:length(GS3_DATA_mes(:,1))
                data_interp_gs3=interp1(T_GS3,GS3_DATA_mes(i,5:end),T_interp_2);
                GS3_DATA(i,6:length(T_interp_2)+5)=data_interp_gs3';
            end
            
            % Résistivité de l'Eau
            GS3_DATA_EAU=GS3_DATA_E4D(:,1:5);
            for i=1:length(GS3_DATA_EAU_mes(:,1))
                data_interp_gs3=interp1(T_GS3_RES_EAU,GS3_DATA_EAU_mes(i,5:end),T_interp_2);
                GS3_DATA_EAU(i,6:length(T_interp_2)+5)=data_interp_gs3';
            end
            
            
            pas_de_temps=1;
            format=formatOut1;
            
            
            % Matrices d'informations
            LYSI_INFO{1}=['Lysimètre 1'];
            LYSI_INFO{2}=['Lysimètre 2'];
            LYSI_INFO{3}=['Lysimètre 3'];
            LYSI_INFO{4}=['Lysimètre 4'];
            LYSI_INFO{5}=['Lysimètre 5'];
            LYSI_INFO{6}=['Lysimètre 6'];
            
            NOM_SONDE{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE{2}=['Ilmenite Haut, Z = 1.2 m'];
            NOM_SONDE{1}=['Ilmenite Bas, Z = 1.5 m'];
            NOM_SONDE{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE{7}=['Sable Base N2, Z = 7 m'];
            
            NOM_SONDE_an{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE_an{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE_an{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE_an{2}=['Anorthosite Haut, Z = 1.2 m'];
            NOM_SONDE_an{1}=['Anorthosite Bas, Z = 1.5 m'];
            NOM_SONDE_an{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE_an{7}=['Sable Base N2, Z = 7 m'];
            
            load    GS3_DATA_E4D_avec_lysi.mat
            load T_interp_2_avec_lysi.mat
            load    GS3_DATA_E4D_sans_lysi.mat
            load T_interp_2_sans_lysi.mat
            % FIGURES
            figure('Color', [ 1 1 1])
            hold on
            for lysi=1
                for sonde=5
                    
                    ind_ligne=(lysi-1)*7+sonde;
                    
                    
                    
                    %                    % TEMP sable haut lys 4
                    %             TEMP_DATA_2=interp1(TEMP_DATA(:,1)+1.5  ,TEMP_DATA(:,2),T_interp_2);
                    %               % Res mesurée GS3
                    %                     plot(T_interp_2,TEMP_DATA_2(:,1),'.-g','LineWidth',3,'MarkerSize',10)
                    %                     ylabel({'Temperature';'(GS3 sensors) (°C)'},'FontSize',14,'FontWeight','bold')
                    
                    
                    % Res mesurée GS3
                    plot(T_interp_2(1:end,1),GS3_DATA_EAU(ind_ligne,6:end)','.-','LineWidth',4,'MarkerSize',10)
                    ylabel({'Water Electrical Resistivity';'(GS3 sensors) (\Omega.m)'},'FontSize',14,'FontWeight','bold')
                end
            end
            % Teneur en eau sable haut lys 4
            load VWC_DATA_AN
            VWC_DATA_AN_2=interp1(VWC_DATA_AN(:,1)-T_CORR,VWC_DATA_AN(:,2),T_interp_2);
            
            %ylim([-1000 2500])
            yyaxis right
            plot(T_interp_2,VWC_DATA_AN_2(:,1)*100,'.-','LineWidth',4,'MarkerSize',10)
            hold on
            %             %ylim([0.22 0.5])
            ylabel({'Volumetric Water Content';'(GS3 sensors) (%)'},'FontSize',14,'FontWeight','bold')
            
            % ylim([0 6000])
            
            hold on
            
            xlabel({'Elapsed time (dd/mm/yy)'},'FontSize',14,'FontWeight','bold')
            if time_lapse==1
                title_spec='COMPARAISON TIME-LAPSE : ';
            else
                title_spec='COMPARAISON STATIQUE : ';
            end
            
            grid
            ax = gca;
            ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
            ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
            
            %             for o=1
            %                 axes('Position',[.44 .45 .45 .45])
            %
            %                 hold on
            %                 hold on
            %                 for lysi=4
            %                     for sonde=4
            %
            %                         ind_ligne=(lysi-1)*7+sonde;
            %
            %
            %
            %                         % TEMP sable haut lys 4
            %                         TEMP_DATA_2=interp1(TEMP_DATA(:,1)+1.5  ,TEMP_DATA(:,2),T_interp_2);
            %                         % Res mesurée GS3
            %                         plot(T_interp_2,TEMP_DATA_2(:,1),'.-g','LineWidth',3,'MarkerSize',10)
            %                         ylabel({'Temperature';'(GS3 sensors) (°C)'},'FontSize',14,'FontWeight','bold')
            %
            %
            %                         %                     % Res mesurée GS3
            %                         %                     plot(T_interp_2(1:end,1),GS3_DATA_EAU(ind_ligne,6:end)','.-','LineWidth',4,'MarkerSize',10)
            %                         %                     ylabel({'Water Electrical Resistivity';'(GS3 sensors) (\Omega.m)'},'FontSize',14,'FontWeight','bold')
            %                     end
            %                 end
            %                 % Teneur en eau sable haut lys 4
            %                 %                         VWC_DATA_2=interp1(VWC_DATA(:,1)-T_CORR,VWC_DATA(:,2),T_interp_2);
            %                 %
            %                 %             %ylim([-1000 2500])
            %                 %                            yyaxis right
            %                 %                         plot(T_interp_2,VWC_DATA_2(:,1)-0.16,'.-','LineWidth',4,'MarkerSize',10)
            %                 %                         hold on
            %                 %             %             %ylim([0.22 0.5])
            %                 %                         ylabel({'Volumetric Water Content';'(GS3 sensors) (%)'},'FontSize',14,'FontWeight','bold')
            %                 %
            %                 % ylim([0 6000])
            %
            %                 hold on
            %                 if time_lapse==1
            %                     title_spec='COMPARAISON TIME-LAPSE : ';
            %                 else
            %                     title_spec='COMPARAISON STATIQUE : ';
            %                 end
            %
            %                 grid
            %                 ax = gca;
            %                 ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
            %                 ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
            %             end
        end
    end
    
    %% II - FIGURE 11
    actif=0;
    for o=1
        if actif==1
            p = get(gcf,'Position');
            set(0,'DefaultFigurePosition',p);
            close all
            load T_GS3.mat
            load GS3_DATA_mes.mat
            load T_GS3_RES_EAU.mat
            load GS3_DATA_EAU_mes.mat
            
            % Résistivité du sol
            GS3_DATA=GS3_DATA_E4D(:,1:5);
            for i=1:length(GS3_DATA_mes(:,1))
                data_interp_gs3=interp1(T_GS3,GS3_DATA_mes(i,5:end),T_interp_2);
                GS3_DATA(i,6:length(T_interp_2)+5)=data_interp_gs3';
            end
            
            % Résistivité de l'Eau
            GS3_DATA_EAU=GS3_DATA_E4D(:,1:5);
            for i=1:length(GS3_DATA_EAU_mes(:,1))
                data_interp_gs3=interp1(T_GS3_RES_EAU,GS3_DATA_EAU_mes(i,5:end),T_interp_2);
                GS3_DATA_EAU(i,6:length(T_interp_2)+5)=data_interp_gs3';
            end
            
            
            pas_de_temps=1;
            format=formatOut1;
            
            
            % Matrices d'informations
            LYSI_INFO{1}=['Lysimètre 1'];
            LYSI_INFO{2}=['Lysimètre 2'];
            LYSI_INFO{3}=['Lysimètre 3'];
            LYSI_INFO{4}=['Lysimètre 4'];
            LYSI_INFO{5}=['Lysimètre 5'];
            LYSI_INFO{6}=['Lysimètre 6'];
            
            NOM_SONDE{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE{2}=['Ilmenite Haut, Z = 1.2 m'];
            NOM_SONDE{1}=['Ilmenite Bas, Z = 1.5 m'];
            NOM_SONDE{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE{7}=['Sable Base N2, Z = 7 m'];
            
            NOM_SONDE_an{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE_an{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE_an{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE_an{2}=['Anorthosite Haut, Z = 1.2 m'];
            NOM_SONDE_an{1}=['Anorthosite Bas, Z = 1.5 m'];
            NOM_SONDE_an{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE_an{7}=['Sable Base N2, Z = 7 m'];
            
            load    GS3_DATA_E4D_avec_lysi.mat
            load T_interp_2_avec_lysi.mat
            load    GS3_DATA_E4D_sans_lysi.mat
            load T_interp_2_sans_lysi.mat
            % FIGURES
            figure('Color', [ 1 1 1])
            hold on
            for lysi=1:6
                for sonde=2
                    
                    ind_ligne=(lysi-1)*7+sonde;
                    
                    
                    
                    %                    % TEMP sable haut lys 4
                    %             TEMP_DATA_2=interp1(TEMP_DATA(:,1)+1.5  ,TEMP_DATA(:,2),T_interp_2);
                    %               % Res mesurée GS3
                    %                     plot(T_interp_2,TEMP_DATA_2(:,1),'.-g','LineWidth',3,'MarkerSize',10)
                    %                     ylabel({'Temperature';'(GS3 sensors) (°C)'},'FontSize',14,'FontWeight','bold')
                    
                    
                    % Res mesurée GS3
                    plot(T_interp_2(1:end,1),GS3_DATA_EAU(ind_ligne,6:end)','.-','LineWidth',4,'MarkerSize',10)
                    ylabel({'Water Electrical Resistivity';'(GS3 sensors) (\Omega.m)'},'FontSize',14,'FontWeight','bold')
                end
            end
            % Teneur en eau sable haut lys 4
            %             VWC_DATA_2=interp1(VWC_DATA(:,1)-T_CORR,VWC_DATA(:,2),T_interp_2);
            %
            %ylim([-1000 2500])
            %                yyaxis right
            %             plot(T_interp_2,VWC_DATA_2(:,1),'.-','LineWidth',4,'MarkerSize',10)
            %             hold on
            %             %ylim([0.22 0.5])
            %             ylabel({'Volumetric Water Content';'(GS3 sensors) (%)'},'FontSize',14,'FontWeight','bold')
            %
            % ylim([0 6000])
            
            hold on
            
            xlabel({'Elapsed time (dd/mm/yy)'},'FontSize',14,'FontWeight','bold')
            if time_lapse==1
                title_spec='COMPARAISON TIME-LAPSE : ';
            else
                title_spec='COMPARAISON STATIQUE : ';
            end
            
            grid
            ax = gca;
            ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
            ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
            
        end
    end
    
    %% II - 4 Superposition des données E4D et des données mesurées GS3 % NORMALISÉES
    actif=1;
    for o=1
        if actif==1
            p = get(gcf,'Position');
            set(0,'DefaultFigurePosition',p);
            close all
            load T_GS3.mat
            load GS3_DATA_mes.mat
            load T_GS3_RES_EAU.mat
            load GS3_DATA_EAU_mes.mat
            
            % Résistivité du sol
            GS3_DATA=GS3_DATA_E4D(:,1:5);
            for i=1:length(GS3_DATA_mes(:,1))
                data_interp_gs3=interp1(T_GS3,GS3_DATA_mes(i,5:end),T_interp_2);
                GS3_DATA(i,6:length(T_interp_2)+5)=data_interp_gs3';
            end
            
            % Résistivité de l'Eau
            GS3_DATA_EAU=GS3_DATA_E4D(:,1:5);
            for i=1:length(GS3_DATA_EAU_mes(:,1))
                data_interp_gs3=interp1(T_GS3_RES_EAU,GS3_DATA_EAU_mes(i,5:end),T_interp_2);
                GS3_DATA_EAU(i,6:length(T_interp_2)+5)=data_interp_gs3';
            end
            
            
            pas_de_temps=0.25;
            format=formatOut2;
            
            
            % Matrices d'informations
            LYSI_INFO{1}=['Lysimètre 1'];
            LYSI_INFO{2}=['Lysimètre 2'];
            LYSI_INFO{3}=['Lysimètre 3'];
            LYSI_INFO{4}=['Lysimètre 4'];
            LYSI_INFO{5}=['Lysimètre 5'];
            LYSI_INFO{6}=['Lysimètre 6'];
            
            NOM_SONDE{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE{2}=['Ilmenite Haut, Z = 1.2 m'];
            NOM_SONDE{1}=['Ilmenite Bas, Z = 1.5 m'];
            NOM_SONDE{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE{7}=['Sable Base N2, Z = 7 m'];
            
            NOM_SONDE_an{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE_an{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE_an{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE_an{2}=['Anorthosite Haut, Z = 1.2 m'];
            NOM_SONDE_an{1}=['Anorthosite Bas, Z = 1.5 m'];
            NOM_SONDE_an{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE_an{7}=['Sable Base N2, Z = 7 m'];
            
            load    GS3_DATA_E4D_avec_lysi.mat
            load T_interp_2_avec_lysi.mat
            load    GS3_DATA_E4D_sans_lysi.mat
            load T_interp_2_sans_lysi.mat
            % FIGURES
            figure('Color', [ 1 1 1])
            hold on
            
            MATRICE=T_interp_2(1:end,1);
            for lysi=6
                for sonde=1:5
                    
                    ind_ligne=(lysi-1)*7+sonde;
                    
                    colonne=colonne+1;
                    MATRICE=[MATRICE,GS3_DATA(ind_ligne,6:end)'];
                    
                end
            end
            MATRICE(MATRICE(:,1)<42892,:)=[];
            MATRICE(MATRICE(:,1)>42895,:)=[];
            
            MATRICE_2=MATRICE;
            for i=2:6
                MATRICE_2(:,i)=MATRICE_2(:,i)-min(MATRICE_2(:,i));
                MATRICE_2(:,i)=MATRICE_2(:,i)/max(MATRICE_2(:,i));
            end
            
            % Affichage
            figure('Color', [ 1 1 1])
            hold on
            for i=2:6
                plot(MATRICE_2(:,1),MATRICE_2(:,i),'.-','LineWidth',4,'MarkerSize',10)
            end
            
            hold on
            
            xlabel({'Elapsed time (dd/mm/yy)'},'FontSize',14,'FontWeight','bold')
            
            grid
            ax = gca;
            ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
            ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
            
        end
    end
    
    %% II - 4 Superposition des données E4D et des données mesurées GS3 % NORMALISÉES
    actif=1;
    for o=1
        if actif==1
            p = get(gcf,'Position');
            set(0,'DefaultFigurePosition',p);
            close all
            load T_GS3.mat
            load GS3_DATA_mes.mat
            load T_GS3_RES_EAU.mat
            load GS3_DATA_EAU_mes.mat
            
            % Résistivité du sol
            GS3_DATA=GS3_DATA_E4D(:,1:5);
            for i=1:length(GS3_DATA_mes(:,1))
                data_interp_gs3=interp1(T_GS3,GS3_DATA_mes(i,5:end),T_interp_2);
                GS3_DATA(i,6:length(T_interp_2)+5)=data_interp_gs3';
            end
            
            % Résistivité de l'Eau
            GS3_DATA_EAU=GS3_DATA_E4D(:,1:5);
            for i=1:length(GS3_DATA_EAU_mes(:,1))
                data_interp_gs3=interp1(T_GS3_RES_EAU,GS3_DATA_EAU_mes(i,5:end),T_interp_2);
                GS3_DATA_EAU(i,6:length(T_interp_2)+5)=data_interp_gs3';
            end
            
            
            
            
            pas_de_temps=0.25;
            format=formatOut2;
            
            
            % Matrices d'informations
            LYSI_INFO{1}=['Lysimètre 1'];
            LYSI_INFO{2}=['Lysimètre 2'];
            LYSI_INFO{3}=['Lysimètre 3'];
            LYSI_INFO{4}=['Lysimètre 4'];
            LYSI_INFO{5}=['Lysimètre 5'];
            LYSI_INFO{6}=['Lysimètre 6'];
            
            NOM_SONDE{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE{2}=['Ilmenite Haut, Z = 1.2 m'];
            NOM_SONDE{1}=['Ilmenite Bas, Z = 1.5 m'];
            NOM_SONDE{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE{7}=['Sable Base N2, Z = 7 m'];
            
            NOM_SONDE_an{5}=['Anorthosite Haut, Z = 0.15 m'];
            NOM_SONDE_an{4}=['Sable Haut, Z = 0.6 m'];
            NOM_SONDE_an{3}=['Sable Bas, Z = 0.9 m'];
            NOM_SONDE_an{2}=['Anorthosite Haut, Z = 1.2 m'];
            NOM_SONDE_an{1}=['Anorthosite Bas, Z = 1.5 m'];
            NOM_SONDE_an{6}=['Sable Base N1, Z = 7 m'];
            NOM_SONDE_an{7}=['Sable Base N2, Z = 7 m'];
            
            load    GS3_DATA_E4D_avec_lysi.mat
            load T_interp_2_avec_lysi.mat
            load    GS3_DATA_E4D_sans_lysi.mat
            load T_interp_2_sans_lysi.mat
            % FIGURES
            figure('Color', [ 1 1 1])
            hold on
            
            MATRICE=T_interp_2(1:end,1);
            for lysi=6
                for sonde=1:5
                    
                    ind_ligne=(lysi-1)*7+sonde;
                    
                    colonne=colonne+1;
                    MATRICE=[MATRICE,GS3_DATA(ind_ligne,6:end)'];
                    
                end
            end
            MATRICE(MATRICE(:,1)<42892,:)=[];
            MATRICE(MATRICE(:,1)>42895,:)=[];
            
            MATRICE_2=MATRICE;
            for i=2:6
                MATRICE_2(:,i)=MATRICE_2(:,i)-min(MATRICE_2(:,i));
                MATRICE_2(:,i)=MATRICE_2(:,i)/max(MATRICE_2(:,i));
            end
            
            % Affichage
            
            for i=2:6
                
                plot(MATRICE_2(:,1),MATRICE_2(:,i),'.-','LineWidth',4,'MarkerSize',10)
            end
            
            
            xlabel({'Elapsed time (dd/mm/yy)'},'FontSize',14,'FontWeight','bold')
            
            grid
            ax = gca;
            ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
            ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
            
        end
    end
    
    
    %% II - 5 Affichage des données d'inversions pour chaque type de GS3
    actif=0;
    for o=1
        if actif==1
            close all
            pas_de_temps=1/12;
            formatOut2= 'dd/mm HH AM';
            format=formatOut2;
            
            for sonde=1:7
                figure('Color', [ 1 1 1])
                for lysi=6
                    
                    ind_ligne=(lysi-1)*7+sonde;
                    plot(T_interp_2(1:end-1,1),GS3_DATA_E4D(ind_ligne,6:end)','.-','LineWidth',4,'MarkerSize',10,'DisplayName',['lysi ',num2str(lysi)])
                    hold on
                end
                
                ylabel({'Resistiviy calculated after inversion (E4D)';'(Ohm.m)'},'FontSize',14,'FontWeight','bold')
                xlabel({'Elapsed time (dd/mm/yy)'},'FontSize',14,'FontWeight','bold')
                grid minor
                legend show
                title_spec='COMPARAISON TIME-LAPSE : ';
                title([title_spec,LYSI_INFO{lysi},' : ',NOM_SONDE{sonde}],'FontSize',12,'FontWeight','bold' )
                grid
                ax = gca;
                ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
                ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
                
            end
        end
    end
    
    %% II - 6 Tracé d'une coupe 2D de la halde au cours du temps
    actif=1;
    for o=1
        if actif==1
            %% II - 6 a Données de la coupe 2D et histogramme
            for o=1
                Xmin=30;
                Xmax=90;
                Ymin=23.8;
                Ymax=24.2;
                Zmin=1.5;
                clear ELEMENT_SELECT
                ELEMENT_SELECT=Barycentre(find(Barycentre(:,2)>Xmin & Barycentre(:,2)<Xmax & Barycentre(:,3)>Ymin & Barycentre(:,3)<Ymax & Barycentre(:,4)>Zmin),:);
                % figure
                % plot3(ELEMENT_SELECT(:,2),ELEMENT_SELECT(:,3),ELEMENT_SELECT(:,4),'.k')
                
                Results_E4D_R_SELECT=[ELEMENT_SELECT,Results_E4D_R(ELEMENT_SELECT(:,1)+3,2:end-1)];
                
                Results_E4D_R_SELECT_log=Results_E4D_R_SELECT;
                Results_E4D_R_SELECT_log(:,5:end)=log(Results_E4D_R_SELECT_log(:,5:end));
                
                % Affichage de l'histogramme des données log
                figure('Color', [ 1 1 1])
                histogram(Results_E4D_R_SELECT_log(:,4:end),100)
                xlim([2 12])
                title('Histogramme de valeurs de résistivité (Ohm.m)','FontSize',16)
                xlabel('Valeur de résistivité en Ohm.m')
                ylabel('Nombre de valeurs dans chaque catégories')
                TicksM = [2;4;6;8;10;12;14;16];
                TicksL = round(exp(TicksM),0);
                ax = gca;
                ax.XTick=[2;4;6;8;10;12;14;16];
                ax.XTickLabel =round(exp(TicksM),0);
                grid
                grid minor
                
                % Troncature MIN au choix de l'utilisateur
                p = get(gcf,'Position');
                for o=1
                    d = dialog('Name','Choix de la valeur minimale de resistivité');
                    
                    txt = uicontrol('Parent',d,...
                        'Style','text',...
                        'Position',[100 200 210 80],...
                        'String',['Select the minimum resistivity value needed in Ohm.m (log values)'],...
                        'Fontsize',10);
                    
                    btn = uicontrol('Parent',d,...
                        'Position',[170 20 70 25],...
                        'String','Close',...
                        'Callback','delete(gcf)');
                end % Dialog box
                
                CutOff_MIN=ginput(1);
                CutOff_MIN=round(CutOff_MIN(:,1),2);
                
                % Troncature MAX au choix de l'utilisateur
                p = get(gcf,'Position');
                for o=1
                    d = dialog('Name','Choix de la valeur maximale de resistivité');
                    
                    txt = uicontrol('Parent',d,...
                        'Style','text',...
                        'Position',[100 200 210 80],...
                        'String',['Select the maximum resistivity value needed in Ohm.m (log values)'],...
                        'Fontsize',10);
                    
                    btn = uicontrol('Parent',d,...
                        'Position',[170 20 70 25],...
                        'String','Close',...
                        'Callback','delete(gcf)');
                end % Dialog box
                
                CutOff_MAX=ginput(1);
                CutOff_MAX=round(CutOff_MAX(:,1),2);
                
                close
                % echelle de couleur de 0 a 1
                % echelle de valeur de R_min a R_max
                for i=5:length(Results_E4D_R_SELECT_log(1,:))
                    Results_E4D_R_SELECT_log(Results_E4D_R_SELECT_log(:,i)<=CutOff_MIN,i)=CutOff_MIN;
                    Results_E4D_R_SELECT_log(Results_E4D_R_SELECT_log(:,i)>=CutOff_MAX,i)=CutOff_MAX;
                    Results_E4D_R_SELECT_log(:,i)=Results_E4D_R_SELECT_log(:,i)-CutOff_MIN;
                    Results_E4D_R_SELECT_log(:,i)=round(Results_E4D_R_SELECT_log(:,i)/(CutOff_MAX-CutOff_MIN)*100);
                    Results_E4D_R_SELECT_log(Results_E4D_R_SELECT_log(:,i)==0,i)=1;
                end
            end
            
            %% II - 6 b MAILLAGE DE LA COUPE 2D et affichage
            for o=1
                pas_X=0.005;
                pas_Z=0.05;
                
                Zmax=9;
                [X_coupe,Z_coupe] = meshgrid(Xmin:pas_X:Xmax,Zmin:pas_Z:Zmax);
                value = griddata(Results_E4D_R_SELECT_log(:,2),Results_E4D_R_SELECT_log(:,4),Results_E4D_R_SELECT_log(:,5),X_coupe,Z_coupe,'cubic');
                
                figure('Color', [ 1 1 1])
                colormap ((jet(100)));
                cmap = colormap;
                pcolor(X_coupe,Z_coupe,value);
                shading flat
                hold on
                contour(X_coupe,Z_coupe,value,5,'LineWidth',0.7,'LineColor','k')
                
                % Colorbar
                % Légende
                clear colorbar
                colormap ((jet(100)));
                colorbar;
                caxis([0 100]);
                TicksM = [1;20;40;60;80;100];
                TicksL = round(exp((TicksM/100)*(CutOff_MAX-CutOff_MIN)+CutOff_MIN),0);
                
                
                c=colorbar;
                c.Label.String = 'Resistance entre les électrodes C1 et C2 (Ohms)';
                c.Label.FontWeight='bold';
                c.Label.FontSize=14;
                c.Ticks=TicksM;
                c.TickLabels={num2str(TicksL)};
                c.Location='southoutside';
                daspect([1,1,1])
                
                % Affichage des électrodes
                
            end
        end
    end
    
    %% II - 7 Visualisation 3D de la halde - RÉSISTIVITÉ
    actif=1;
    for o=1
        %% II - 7 a SELECTION DES DONNÉES
        for o=1
            if actif==1
                pas_SELECT_X=0.5;
                pas_SELECT_Y=0.5;
                rayon_influence=0.1;
                ELEMENT_SELECT_3D=[0,0,0,0];
                for i=0:(92-29)/pas_SELECT_X
                    for j=0:(32-20)/pas_SELECT_Y
                        ELEMENT_SELECT_3D=[ELEMENT_SELECT_3D;Barycentre(find(Barycentre(:,2)>(29+i*pas_SELECT_X-rayon_influence) & Barycentre(:,2)<(29+i*pas_SELECT_X+rayon_influence) & Barycentre(:,3)>(20+j*pas_SELECT_Y-rayon_influence) & Barycentre(:,3)<(20+j*pas_SELECT_Y+rayon_influence) & Barycentre(:,4)>1.7),:)];
                        avancement=round(i/((92-29)/pas_SELECT_X),2)*100
                    end
                end
                ELEMENT_SELECT_3D(1,:)=[];
                
                %                 figure
                %                 plot3(ELEMENT_SELECT_3D(:,2),ELEMENT_SELECT_3D(:,3),ELEMENT_SELECT_3D(:,4),'.k')
                
                DATA_TO_PLOT_3D=ELEMENT_SELECT_3D;
                DATA_TO_PLOT_3D(:,5)=Results_E4D_R(ELEMENT_SELECT_3D(:,1)+3,2);
                
                DATA_TO_PLOT_3D(:,6)=log(DATA_TO_PLOT_3D(:,5));
            end
        end
        
        %% II - 7 b ÉGALISATION D'HISTOGRAMME
        for o=1
            if actif==1
                % Affichage de l'histogramme des données log
                figure('Color', [ 1 1 1])
                histogram(DATA_TO_PLOT_3D(DATA_TO_PLOT_3D(:,6)<12,6),100)
                title('Histogramme de valeurs de résistivité (Ohm.m)','FontSize',16)
                xlabel('Valeur de résistivité en Ohm.m')
                ylabel('Nombre de valeurs dans chaque catégories')
                TicksM = [2;4;6;8;10;12;14;16];
                TicksL = round(exp(TicksM),0);
                ax = gca;
                ax.XTick=[2;4;6;8;10;12;14;16];
                ax.XTickLabel =round(exp(TicksM),0);
                grid
                grid minor
                
                % Troncature MIN au choix de l'utilisateur
                p = get(gcf,'Position');
                for o=1
                    d = dialog('Position',[p(1)+800,p(2)+300,400,400],'Name','Choix de la valeur minimale de resistivité');
                    
                    txt = uicontrol('Parent',d,...
                        'Style','text',...
                        'Position',[100 200 210 80],...
                        'String',['Select the minimum resistivity value needed in Ohm.m (log values)'],...
                        'Fontsize',10);
                    
                    btn = uicontrol('Parent',d,...
                        'Position',[170 20 70 25],...
                        'String','Close',...
                        'Callback','delete(gcf)');
                end % Dialog box
                
                CutOff_MIN=ginput(1);
                CutOff_MIN=round(CutOff_MIN(:,1),2);
                
                % Troncature MAX au choix de l'utilisateur
                p = get(gcf,'Position');
                for o=1
                    d = dialog('Position',[p(1)+800,p(2)+300,400,400],'Name','Choix de la valeur maximale de resistivité');
                    
                    txt = uicontrol('Parent',d,...
                        'Style','text',...
                        'Position',[100 200 210 80],...
                        'String',['Select the maximum resistivity value needed in Ohm.m (log values)'],...
                        'Fontsize',10);
                    
                    btn = uicontrol('Parent',d,...
                        'Position',[170 20 70 25],...
                        'String','Close',...
                        'Callback','delete(gcf)');
                end % Dialog box
                
                CutOff_MAX=ginput(1);
                CutOff_MAX=round(CutOff_MAX(:,1),2);
                
                close
                % echelle de couleur de 0 a 1
                % echelle de valeur de R_min a R_max
                DATA_TO_PLOT_3D(:,7)=DATA_TO_PLOT_3D(:,6);
                DATA_TO_PLOT_3D(DATA_TO_PLOT_3D(:,7)<=CutOff_MIN,7)=CutOff_MIN;
                
                DATA_TO_PLOT_3D(DATA_TO_PLOT_3D(:,7)>=CutOff_MAX,7)=CutOff_MAX;
                
                DATA_TO_PLOT_3D(:,7)=DATA_TO_PLOT_3D(:,7)-CutOff_MIN;
                
                DATA_TO_PLOT_3D(:,7)=round(DATA_TO_PLOT_3D(:,7)/(CutOff_MAX-CutOff_MIN)*100);
                % 0->1
                DATA_TO_PLOT_3D(DATA_TO_PLOT_3D(:,7)==0,7)=1;
            end
        end
        
        %% II - 7 c MAILLAGE DE LA HALDE ET INTERPOLATION
        for o=1
            % Maillage de la halde 3D
            for o=1
                pas_X=0.5;
                pas_Y=0.5;
                pas_Z=0.1;
                
                [X_halde,Y_halde,Z_halde] = meshgrid(30:pas_X:92,21:pas_Y:31,2:pas_Z:9);
            end
            
            % Maillage de la surface de la halde pour calcul Z  -> dans ARP_NEW
            for o=1
                load Maillage3DSurface.mat
                Maillage3DSurface=Maillage3DSurface+0.01;
                DATA2=Maillage3DSurface;
                
                
                % Maillage régulier de la halde
                [X_surf,Y_surf]=meshgrid(30:pas_X:92,21:pas_Y:31);
                
                Interp_Zmemoire=zeros(length(X_surf(:,1)),length(X_surf(1,:)));
                INmemoire=zeros(length(X_surf(:,1)),length(X_surf(1,:)));
                for i=1:length(DATA2(:,1))/3 % test pour chaque polygone constituant le maillage
                    ii=(i-1)*3+1;
                    IN = inpolygon(X_surf(:,:),Y_surf(:,:),DATA2(ii:ii+2,1),DATA2(ii:ii+2,2)); % test pour chaque point du maillage régulier
                    IN=IN-INmemoire;
                    IN(IN(:,:)==-1)=0;
                    INmemoire=INmemoire+IN;
                    % Equation du plan
                    A=DATA2(ii,1:3);
                    B=DATA2(ii+1,1:3);
                    C=DATA2(ii+2,1:3);
                    AB=B-A;
                    AC=C-A;
                    n=cross(AB,AC);
                    Interp_Z=A(3)-(n(1)*(X_surf-A(1))+n(2)*(Y_surf-A(2)))/n(3);
                    Interp_Z=Interp_Z.*IN;
                    Interp_Zmemoire=Interp_Zmemoire+Interp_Z;
                end
                
                clear ARP_NEW
                ARP_NEW=0;
                for i=1:length(X_surf(:,1))
                    for j=1:length(X_surf(1,:))
                        ARP_NEW(end+1,1)=X_surf(i,j);
                        ARP_NEW(end,2)=Y_surf(i,j);
                        ARP_NEW(end,3)=Interp_Zmemoire(i,j);
                    end
                end
                
                ARP_NEW(1,:)=[];
                ARP_NEW(ARP_NEW(:,1)==0,:)=[];
                ARP_NEW(ARP_NEW(:,2)==0,:)=[];
                ARP_NEW(ARP_NEW(:,1)==110,:)=[];
                ARP_NEW(ARP_NEW(:,2)==50,:)=[];
                ARP_NEW(ARP_NEW(:,3)==0,:)=[];
                
                %         figure('Color', [ 1 1 1])
                %         hold on
                %         plot3(ARP_NEW(:,1),ARP_NEW(:,2),ARP_NEW(:,3),'.')
                %         daspect([1,1,0.5])
                %         view(101.34,20.48)
                %         %camzoom(2)
            end
            
            
            F = scatteredInterpolant(DATA_TO_PLOT_3D(:,2),DATA_TO_PLOT_3D(:,3),DATA_TO_PLOT_3D(:,4),DATA_TO_PLOT_3D(:,7),'natural');
            vq = F(X_halde,Y_halde,Z_halde);
            
            % Suppression des données au dessus de la surface
            for o=1
                for xi=1:length(X_halde(1,:,1))
                    for yi=1:length(X_halde(:,1,1))
                        for zi=1:length(X_halde(1,1,:))
                            ligne=find(ARP_NEW(:,1)==X_halde(yi,xi,zi)&ARP_NEW(:,2)==Y_halde(yi,xi,zi));
                            if Z_halde(yi,xi,zi)>ARP_NEW(ligne,3);
                                vq(yi,xi,zi)=NaN;
                            end
                        end
                    end
                end
            end
        end
        
        %% II - 7 d AFFICHAGE 3D DE LA HALDE
        volume=0;
        interieur=0;
        Valeur=70;
        for o=1
            if actif==1
                
                p = get(gcf,'Position');
                set(0,'DefaultFigurePosition',p);
                close all
                figure('color',[1 1 1])
                hold on
                
                
                daspect([1 1 1])
                plot3(Maillage3DSurface_2(:,1),Maillage3DSurface_2(:,2),Maillage3DSurface_2(:,3),'-k','LineWidth',0.875)
                plot3(ELEC(:,1),ELEC(:,2),ELEC(:,3),'k.','MarkerSize',7.5)
                plot3(GS3_location(:,2),GS3_location(:,3),GS3_location(:,4),'g.','MarkerSize',7.5)
                
                view(-38.5,16)
                light('Position',[40 -10 50],'Style','local')
                camzoom(2)
                camproj perspective
                
                Y_COUPE=26;
                % Visualisation d'une coupe 2D de la halde en Y
                for o=1
                    % Plans d'interet
                    p2 = slice(X_halde,Y_halde,Z_halde,vq,[],Y_COUPE,[]);
                    p2.FaceColor = 'interp';
                    p2.EdgeColor = 'none';
                    
                    % lignes
                    % [X_halde,Y_halde,Z_halde] = meshgrid(30:pas_X:92,21:pas_Y:31,2:pas_Z:9);
                    
                    line([30 92],[Y_COUPE Y_COUPE],[2 2],'Color',[0 0 0],'LineWidth',1)
                    line([30 30],[Y_COUPE Y_COUPE],[2 8.4],'Color',[0 0 0],'LineWidth',1)
                    line([92 92],[Y_COUPE Y_COUPE],[2 5.8],'Color',[0 0 0],'LineWidth',1)
                end
                
                % Visualisation d'une coupe 2D de la halde en X
                for GS3_i=1:6
                    X_COUPE=GS3_location((GS3_i-1)*7+1,2);
                    
                    for o=1
                        % Plans d'interet
                        p2 = slice(X_halde,Y_halde,Z_halde,vq,X_COUPE,[],[]);
                        p2.FaceColor = 'interp';
                        p2.EdgeColor = 'none';
                        
                        % lignes
                        % [X_halde,Y_halde,Z_halde] = meshgrid(30:pas_X:92,21:pas_Y:31,2:pas_Z:9);
                        
                        line([X_COUPE X_COUPE],[21 21],[2 GS3_location((GS3_i-1)*7+5,4)],'Color',[0 0 0],'LineWidth',1)
                        line([X_COUPE X_COUPE],[21 31],[2 2],'Color',[0 0 0],'LineWidth',1)
                        line([X_COUPE X_COUPE],[31 31],[2 GS3_location((GS3_i-1)*7+5,4)],'Color',[0 0 0],'LineWidth',1)
                        line([X_COUPE X_COUPE],[Y_COUPE Y_COUPE],[2 GS3_location((GS3_i-1)*7+5,4)],'Color',[0 0 0],'LineWidth',1)
                        
                    end
                end
                
                camzoom(1.3)
                %         p2 = slice(X_halde,Y_halde,Z_halde,vq,[],22,[]);
                %         p2.FaceColor = 'interp';
                %         p2.EdgeColor = 'none';
                
                % Plans d'interet
                %                 p2 = slice(X_halde,Y_halde,Z_halde,vq,[],[],2);
                %                 p2.FaceColor = 'interp';
                %                 p2.EdgeColor = 'none';
                
                % Couleur
                colormap ((jet(100)));
                cmap = colormap;
                % Légende
                clear colorbar
                colormap ((jet(100)));
                colorbar;
                caxis([0 100]);
                TicksM = [1;20;40;60;80;100];
                TicksL = round(exp((TicksM/100)*(CutOff_MAX-CutOff_MIN)+CutOff_MIN),0);
                
                
                c=colorbar;
                c.Label.String = 'Resistance entre les électrodes C1 et C2 (Ohms)';
                c.Label.FontWeight='bold';
                c.Label.FontSize=14;
                c.Ticks=TicksM;
                c.TickLabels={num2str(TicksL)};
                c.Location='southoutside';
                
                
                %     p1=patch(isocaps(X_halde,Y_halde,Z_halde,vq,Valeur,'enclose','below'),'FaceColor','interp','EdgeColor','none');
                %     p1 = patch(isosurface(X_halde,Y_halde,Z_halde,vq,Valeur,'enclose','below'),'FaceColor',cmap(Valeur,:),'EdgeColor','none');
                %     isonormals(X_halde,Y_halde,Z_halde,vq,p1)
                
                if volume==1
                    if interieur==1
                        int_ext='below';
                    else
                        int_ext='above';
                    end
                    p1=patch(isocaps(X_halde,Y_halde,Z_halde,vq,Valeur,'enclose',int_ext),'FaceColor','interp','EdgeColor','none');
                    p1 = patch(isosurface(X_halde,Y_halde,Z_halde,vq,Valeur,'enclose',int_ext),'FaceColor',cmap(Valeur,:),'EdgeColor','none');
                    isonormals(X_halde,Y_halde,Z_halde,vq,p1)
                end
                
            end
        end
        
    end
    
    %% II - 8 Visualisation 3D de la halde - SENSIBILITÉ
    actif=1;
    for o=1
        %% II - 8 a Calcul de la sensibilité 3D du protocole final
        for o=1
            if actif==1
                N_COLUMNS=1;
                
                CONFIGURATIONS_SELECT=PRO_OPT_1000(trouve_2,:);
                MAILLAGE=COORD;
                clear SENSIBILITE_EACH
                SENSIBILITE_EACH=zeros(length(MAILLAGE(:,1)),length(CONFIGURATIONS_SELECT(:,1)));
                
                
                SYNTHESE_VALUES_LIMITE=zeros(length(MAILLAGE(:,1)),N_COLUMNS);
                SYNTHESE_INDICE_LIMITE=zeros(length(MAILLAGE(:,1)),N_COLUMNS);
                erreur_calcul_1=0;
                for i=1:length(CONFIGURATIONS_SELECT(:,1))
                    clear SENSIBILITE_TOT C1_P1 C1_P2 C2_P1 C2_P2
                    C1_P1=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(i,1)&DUOS(:,2)==CONFIGURATIONS_SELECT(i,3)));
                    C2_P1=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(i,2)&DUOS(:,2)==CONFIGURATIONS_SELECT(i,3)));
                    C1_P2=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(i,1)&DUOS(:,2)==CONFIGURATIONS_SELECT(i,4)));
                    C2_P2=SENSIBILITE(:,find(DUOS(:,1)==CONFIGURATIONS_SELECT(i,2)&DUOS(:,2)==CONFIGURATIONS_SELECT(i,4)));
                    if isempty(C1_P1) | isempty(C2_P1) | isempty(C1_P2) | isempty(C2_P2)
                        SENSIBILITE_TOT(:,1)=zeros(length(MAILLAGE(:,1)),1);
                        erreur_calcul_1=erreur_calcul_1+1;
                    else
                        SENSIBILITE_TOT(:,1)=abs(C1_P1-C2_P1-C1_P2+C2_P2);
                    end
                    % SENS_TOT_AVANCEMENT=round(i/length(CONFIGURATIONS_SELECT(:,1))*100,0)
                    
                    SENSIBILITE_EACH(:,i)=SENSIBILITE_TOT(:,1);
                    
                    for j=1:length(MAILLAGE(:,1))
                        trouve=0;
                        for k=1:N_COLUMNS
                            if trouve==0
                                if SENSIBILITE_TOT(j,1)>SYNTHESE_VALUES_LIMITE(j,k)
                                    SYNTHESE_VALUES_LIMITE(j,k+1:end)=SYNTHESE_VALUES_LIMITE(j,k:end-1);
                                    SYNTHESE_VALUES_LIMITE(j,k)=SENSIBILITE_TOT(j,1);
                                    SYNTHESE_INDICE_LIMITE(j,k+1:end)=SYNTHESE_INDICE_LIMITE(j,k:end-1);
                                    SYNTHESE_INDICE_LIMITE(j,k)=i;
                                    trouve=1;
                                end
                            end
                        end
                    end
                end
                erreur_calcul_1
                toc
                
                % Sensibility matrix for the limited protocol
                SENSIBILITE_MATRIX=MAILLAGE;
                SENSIBILITE_MATRIX(:,4)=SYNTHESE_VALUES_LIMITE(:,1);
                
            end
        end
        
        %% II - 8 b Normalisation des données de sensibilité
        for o=1
            SENSIBILITE_DATA=SENSIBILITE_MATRIX;
            SENSIBILITE_DATA(:,5)=log(SENSIBILITE_DATA(:,4));
            
            % Affichage de l'histogramme des données log
            figure('Color', [ 1 1 1])
            histogram(SENSIBILITE_DATA(SENSIBILITE_DATA(:,5)<10,5),100)
            title('Histogramme de valeurs de sensibilité (Ohm.m)','FontSize',16)
            xlabel('Valeur de sensibilié en Ohm.m')
            ylabel('Nombre de valeurs dans chaque catégories')
            TicksM = [0;1;2;3;4;5;6;7];
            TicksL = round(exp(TicksM),0);
            ax = gca;
            ax.XTick=[0;1;2;3;4;5;6;7];
            ax.XTickLabel =round(exp(TicksM),0);
            grid
            grid minor
            
            % Troncature MIN au choix de l'utilisateur
            p = get(gcf,'Position');
            for o=1
                d = dialog('Position',[p(1)+800,p(2)+300,400,400],'Name','Choix de la valeur minimale de sensibilité');
                
                txt = uicontrol('Parent',d,...
                    'Style','text',...
                    'Position',[100 200 210 80],...
                    'String',['Select the minimum sensitivity value needed log values)'],...
                    'Fontsize',10);
                
                btn = uicontrol('Parent',d,...
                    'Position',[170 20 70 25],...
                    'String','Close',...
                    'Callback','delete(gcf)');
            end % Dialog box
            
            CutOff_MIN=ginput(1);
            CutOff_MIN=round(CutOff_MIN(:,1),2);
            
            % Troncature MAX au choix de l'utilisateur
            p = get(gcf,'Position');
            for o=1
                d = dialog('Position',[p(1)+800,p(2)+300,400,400],'Name','Choix de la valeur maximale de sensibilité');
                
                txt = uicontrol('Parent',d,...
                    'Style','text',...
                    'Position',[100 200 210 80],...
                    'String',['Select the maximum sensitivity value needed(log values)'],...
                    'Fontsize',10);
                
                btn = uicontrol('Parent',d,...
                    'Position',[170 20 70 25],...
                    'String','Close',...
                    'Callback','delete(gcf)');
            end % Dialog box
            
            CutOff_MAX=ginput(1);
            CutOff_MAX=round(CutOff_MAX(:,1),2);
            
            close
            % echelle de couleur de 0 a 1
            % echelle de valeur de R_min a R_max
            SENSIBILITE_DATA(:,6)=SENSIBILITE_DATA(:,5);
            SENSIBILITE_DATA(SENSIBILITE_DATA(:,6)<=CutOff_MIN,6)=CutOff_MIN;
            
            SENSIBILITE_DATA(SENSIBILITE_DATA(:,6)>=CutOff_MAX,6)=CutOff_MAX;
            
            SENSIBILITE_DATA(:,6)=SENSIBILITE_DATA(:,6)-CutOff_MIN;
            
            SENSIBILITE_DATA(:,6)=round(SENSIBILITE_DATA(:,6)/(CutOff_MAX-CutOff_MIN)*100);
            % 0->1
            SENSIBILITE_DATA(SENSIBILITE_DATA(:,6)==0,6)=1;
        end
        
        %% II - 8 c Maillage de la halde et interpolation
        for o=1
            
            % Maillage de la halde 3D
            for o=1
                pas_X=0.5;
                pas_Y=0.5;
                pas_Z=0.1;
                
                [X_halde,Y_halde,Z_halde] = meshgrid(30:pas_X:92,21:pas_Y:31,2:pas_Z:9);
            end
            
            % Interpolation
            for o=1
                clearvars F;
                F = scatteredInterpolant(SENSIBILITE_DATA(:,1),SENSIBILITE_DATA(:,2),SENSIBILITE_DATA(:,3),SENSIBILITE_DATA(:,6),'natural');
                vq = F(X_halde,Y_halde,Z_halde);
            end
            
            % Maillage de la surface de la halde pour calcul Z  -> dans ARP_NEW
            for o=1
                load Maillage3DSurface.mat
                Maillage3DSurface=Maillage3DSurface+0.01;
                DATA2=Maillage3DSurface;
                
                
                % Maillage régulier de la halde
                [X_surf,Y_surf]=meshgrid(30:pas_X:92,21:pas_Y:31);
                
                Interp_Zmemoire=zeros(length(X_surf(:,1)),length(X_surf(1,:)));
                INmemoire=zeros(length(X_surf(:,1)),length(X_surf(1,:)));
                for i=1:length(DATA2(:,1))/3 % test pour chaque polygone constituant le maillage
                    ii=(i-1)*3+1;
                    IN = inpolygon(X_surf(:,:),Y_surf(:,:),DATA2(ii:ii+2,1),DATA2(ii:ii+2,2)); % test pour chaque point du maillage régulier
                    IN=IN-INmemoire;
                    IN(IN(:,:)==-1)=0;
                    INmemoire=INmemoire+IN;
                    % Equation du plan
                    A=DATA2(ii,1:3);
                    B=DATA2(ii+1,1:3);
                    C=DATA2(ii+2,1:3);
                    AB=B-A;
                    AC=C-A;
                    n=cross(AB,AC);
                    Interp_Z=A(3)-(n(1)*(X_surf-A(1))+n(2)*(Y_surf-A(2)))/n(3);
                    Interp_Z=Interp_Z.*IN;
                    Interp_Zmemoire=Interp_Zmemoire+Interp_Z;
                end
                
                clear ARP_NEW
                ARP_NEW=0;
                for i=1:length(X_surf(:,1))
                    for j=1:length(X_surf(1,:))
                        ARP_NEW(end+1,1)=X_surf(i,j);
                        ARP_NEW(end,2)=Y_surf(i,j);
                        ARP_NEW(end,3)=Interp_Zmemoire(i,j);
                    end
                end
                
                ARP_NEW(1,:)=[];
                ARP_NEW(ARP_NEW(:,1)==0,:)=[];
                ARP_NEW(ARP_NEW(:,2)==0,:)=[];
                ARP_NEW(ARP_NEW(:,1)==110,:)=[];
                ARP_NEW(ARP_NEW(:,2)==50,:)=[];
                ARP_NEW(ARP_NEW(:,3)==0,:)=[];
                
                %         figure('Color', [ 1 1 1])
                %         hold on
                %         plot3(ARP_NEW(:,1),ARP_NEW(:,2),ARP_NEW(:,3),'.')
                %         daspect([1,1,0.5])
                %         view(101.34,20.48)
                %         %camzoom(2)
            end
            
            % Suppression des données au dessus de la surface
            for o=1
                for xi=1:length(X_halde(1,:,1))
                    for yi=1:length(X_halde(:,1,1))
                        for zi=1:length(X_halde(1,1,:))
                            ligne=find(ARP_NEW(:,1)==X_halde(yi,xi,zi)&ARP_NEW(:,2)==Y_halde(yi,xi,zi));
                            if Z_halde(yi,xi,zi)>ARP_NEW(ligne,3);
                                vq(yi,xi,zi)=NaN;
                            end
                        end
                    end
                end
            end
        end
        
        %% II - 8 d AFFICHAGE 3D DE LA HALDE - SENSIBILITÉS
        volume=0;
        interieur=0;
        Valeur=72;
        for o=1
            if actif==1
                
                p = get(gcf,'Position');
                set(0,'DefaultFigurePosition',p);
                close all
                figure('color',[1 1 1])
                hold on
                
                
                daspect([1 1 1])
                plot3(Maillage3DSurface_2(:,1),Maillage3DSurface_2(:,2),Maillage3DSurface_2(:,3),'-k','LineWidth',0.875)
                plot3(ELEC(:,1),ELEC(:,2),ELEC(:,3),'k.','MarkerSize',7.5)
                plot3(GS3_location(:,2),GS3_location(:,3),GS3_location(:,4),'g.','MarkerSize',7.5)
                
                view(-38.5,16)
                light('Position',[40 -10 50],'Style','local')
                camzoom(2)
                camproj perspective
                
                Y_COUPE=26;
                % Visualisation d'une coupe 2D de la halde en Y -
                % SENSIBILITÉ
                for o=1
                    % Plans d'interet
                    p2 = slice(X_halde,Y_halde,Z_halde,vq,[],Y_COUPE,[]);
                    p2.FaceColor = 'interp';
                    p2.EdgeColor = 'none';
                    
                    % lignes
                    % [X_halde,Y_halde,Z_halde] = meshgrid(30:pas_X:92,21:pas_Y:31,2:pas_Z:9);
                    
                    line([30 92],[Y_COUPE Y_COUPE],[2 2],'Color',[0 0 0],'LineWidth',1)
                    line([30 30],[Y_COUPE Y_COUPE],[2 8.4],'Color',[0 0 0],'LineWidth',1)
                    line([92 92],[Y_COUPE Y_COUPE],[2 5.8],'Color',[0 0 0],'LineWidth',1)
                end
                
                % Visualisation d'une coupe 2D de la halde en X
                for GS3_i=1:6
                    X_COUPE=GS3_location((GS3_i-1)*7+1,2);
                    
                    for o=1
                        % Plans d'interet
                        p2 = slice(X_halde,Y_halde,Z_halde,vq,X_COUPE,[],[]);
                        p2.FaceColor = 'interp';
                        p2.EdgeColor = 'none';
                        
                        % lignes
                        % [X_halde,Y_halde,Z_halde] = meshgrid(30:pas_X:92,21:pas_Y:31,2:pas_Z:9);
                        
                        line([X_COUPE X_COUPE],[21 21],[2 GS3_location((GS3_i-1)*7+5,4)],'Color',[0 0 0],'LineWidth',1)
                        line([X_COUPE X_COUPE],[21 31],[2 2],'Color',[0 0 0],'LineWidth',1)
                        line([X_COUPE X_COUPE],[31 31],[2 GS3_location((GS3_i-1)*7+5,4)],'Color',[0 0 0],'LineWidth',1)
                        line([X_COUPE X_COUPE],[Y_COUPE Y_COUPE],[2 GS3_location((GS3_i-1)*7+5,4)],'Color',[0 0 0],'LineWidth',1)
                    end
                end
                
                camzoom(1.3)
                
                % Couleur
                colormap(flipud(hot(100))); % SENSIBILITÉ
                cmap = colormap;
                % Légende
                clear colorbar
                colormap(flipud(hot(100))); % SENSIBILITÉ
                colorbar;
                caxis([0 100]);
                TicksM = [1;20;40;60;80;100];
                TicksL = round(exp((TicksM/100)*(CutOff_MAX-CutOff_MIN)+CutOff_MIN),0);
                
                
                c=colorbar;
                c.Label.String = 'Resistance entre les électrodes C1 et C2 (Ohms)';
                c.Label.FontWeight='bold';
                c.Label.FontSize=14;
                c.Ticks=TicksM;
                c.TickLabels={num2str(TicksL)};
                c.Location='southoutside';
                
                if volume==1
                    if interieur==1
                        int_ext='below';
                    else
                        int_ext='above';
                    end
                    p1=patch(isocaps(X_halde,Y_halde,Z_halde,vq,Valeur,'enclose',int_ext),'FaceColor','interp','EdgeColor','none','FaceAlpha',0.7);
                    p1 = patch(isosurface(X_halde,Y_halde,Z_halde,vq,Valeur,'enclose',int_ext),'FaceColor',cmap(Valeur,:),'EdgeColor','none','FaceAlpha',0.7);
                    isonormals(X_halde,Y_halde,Z_halde,vq,p1)
                end
                
            end
        end
        
    end
    
    %% II - 9 VISUALISATION DES RÉSULTATS SELON UN "SONDAGE" VERTICAL
    for o=1
        p = get(gcf,'Position');
        set(0,'DefaultFigurePosition',p);
        close all
        T_select=[10,55,240];
        T_col={'k','b','c','m','r'};
        rayon_influence=0.35;
        data_GS3=0;
        figure('color',[1 1 1])
        for i=1:6
            subplot(1,6,i)
            %% II - 9 a SELECTION DES DONNÉES
            for o=1
                
                Xmin=GS3_location((i-1)*7+1,2)-rayon_influence;
                Xmax=GS3_location((i-1)*7+1,2)+rayon_influence;
                Ymin=GS3_location((i-1)*7+1,3)-rayon_influence;
                Ymax=GS3_location((i-1)*7+1,3)+rayon_influence;
                Zmin=2;
                clear ELEMENT_SELECT
                clear Results_E4D_R_SELECT
                ELEMENT_SELECT=Barycentre(find(Barycentre(:,2)>Xmin & Barycentre(:,2)<Xmax & Barycentre(:,3)>Ymin & Barycentre(:,3)<Ymax & Barycentre(:,4)>Zmin),:);
                % figure
                % plot3(ELEMENT_SELECT(:,2),ELEMENT_SELECT(:,3),ELEMENT_SELECT(:,4),'.k')
                
                Results_E4D_R_SELECT=[ELEMENT_SELECT,Results_E4D_R(ELEMENT_SELECT(:,1)+3,2:end-1)];
                Results_E4D_R_SELECT_sorted=sortrows(Results_E4D_R_SELECT,4);
            end
            
            %% II - 9 b AFFICHAGE VERTICAL
            for o=1
                
                for ti=1:length(T_select)
                    t=T_select(ti);
                    Results_E4D_R_SELECT_sorted(Results_E4D_R_SELECT_sorted(:,4+t)>70000,4+t)=70000;
                    semilogx(Results_E4D_R_SELECT_sorted(:,4+t),Results_E4D_R_SELECT_sorted(:,4)-2,['-',T_col{ti}],'MarkerSize',15,'DisplayName',['résistivité du sol (E4D) : t = ',num2str(T_select(ti)-1),' h'],'linewidth',2)
                    hold on
                end
                
                % Affichage des données de GS3 au même moment
                if data_GS3==1
                    GS3_data_local=GS3_DATA((i-1)*7+1:i*7,:);
                    GS3_data_local_sorted=sortrows(GS3_data_local,4);
                    for ti=1:length(T_select)
                        t=T_select(ti);
                        GS3_data_local_sorted(GS3_data_local_sorted(:,4+t)>70000,4+t)=70000;
                        semilogx(GS3_data_local_sorted(:,5+t),GS3_data_local_sorted(:,4)-2,['--o',T_col{ti}],'MarkerSize',10,'MarkerFaceColor','w','LineWidth',3,'DisplayName',['résistivité du sol (GS3) : t = ',num2str(T_select(ti)-1),' h'])
                        hold on
                    end
                end
                
                %                  % Affichage des données de résistivité de l'eau GS3 au même moment
                %                 GS3_data_local=GS3_DATA_EAU((i-1)*7+1:i*7,:);
                %                 GS3_data_local_sorted=sortrows(GS3_data_local,4);
                %                  for ti=1:length(T_select)
                %                     t=T_select(ti);
                %                     GS3_data_local_sorted(GS3_data_local_sorted(:,4+t)>70000,4+t)=70000;
                %                     semilogx(GS3_data_local_sorted(:,5+t),GS3_data_local_sorted(:,4),['--s',T_col{ti}],'MarkerSize',10,'MarkerFaceColor','w','LineWidth',3,'DisplayName',['résistivité de l''eau (GS3) : t = ',num2str(T_select(ti)-1),' h'])
                %                     hold on
                %                  end
                
                if i==6
                    legend('show','Location','southeast')
                end
                grid
                grid minor
                
                %Z_Surface=max(Results_E4D_R_SELECT_sorted(:,4))+0.05;
                [~,ligne]=min((ARP_NEW(:,1)-GS3_location((i-1)*7+1,2)).^2+(ARP_NEW(:,2)-GS3_location((i-1)*7+1,3)).^2);
                Z_Surface=ARP_NEW(ligne,3)-2;
                Z_Base=2-2;
                
                X_MAX_AFF=10000;
                if i==6
                    X_MAX_AFF=100000;
                end
                
                
                x_position_max=50;
                % GS3 location
                Z_GS3=GS3_location((i-1)*7+1:(i-1)*7+6,4)-2;
                for k=1:6
                    line([x_position_max X_MAX_AFF],[Z_GS3(k) Z_GS3(k)],'LineWidth',1.5,'Color','b','LineStyle',':')
                end
                
                ylim([Z_GS3(6)-0.30 Z_Surface+0.05])
                
                % Couches de la halde (lignes horizontales)
                x_position_max=50;
                for o=1
                    line([x_position_max X_MAX_AFF],[Z_Surface Z_Surface],'LineWidth',1.5,'Color','k','LineStyle','-.')
                    % anorth - sable
                    Z_loc=(Z_GS3(5)+Z_GS3(4))/2;
                    line([x_position_max X_MAX_AFF],[Z_loc Z_loc],'LineWidth',1.5,'Color','k','LineStyle','-.')
                    % sable - stériles
                    Z_loc=(Z_GS3(2)+Z_GS3(3))/2;
                    line([x_position_max X_MAX_AFF],[Z_loc Z_loc],'LineWidth',1.5,'Color','k','LineStyle','-.')
                    
                    % stériles - sable
                    Z_loc=Z_GS3(6)+0.15;
                    line([x_position_max X_MAX_AFF],[Z_loc Z_loc],'LineWidth',1.5,'Color','k','LineStyle','-.')
                    
                    % base
                    Z_loc=Z_GS3(6)-0.15;
                    if i==6
                        Z_loc=2.1-2;
                    end
                    line([x_position_max X_MAX_AFF],[Z_loc Z_loc],'LineWidth',1.5,'Color','k','LineStyle','-.')
                end
                
                %
                %                 xlabel({'Resistivité électrique (E4D)';'(\Omega.m)'},'FontSize',14)
                %                 title(['Profil vertical de résistivité électrique (milieu du lysimètre ',num2str(i),')'],'FontSize',16)
                %                 ylabel({'Hauteur dans la halde';'(m)'},'FontSize',14)
                
                xlim([10 10000])
                if i==6
                    xlim([10 100000])
                end
                %ylim([2 9])
                
                % Géométrie de la halde (rectangles de couleur)
                for o=1
                    x_position_min=10;
                    x_position_max=50;
                    % anortho surf
                    rectangle('Position',[x_position_min (Z_GS3(5)+Z_GS3(4))/2 x_position_max-1 Z_Surface-(Z_GS3(5)+Z_GS3(4))/2],'FaceColor',C_anorthosite, 'LineWidth',1)
                    % sable surf
                    rectangle('Position',[x_position_min (Z_GS3(2)+Z_GS3(3))/2 x_position_max-1 (Z_GS3(5)+Z_GS3(4))/2-(Z_GS3(3)+Z_GS3(2))/2],'FaceColor',C_sable ,'LineWidth',1)
                    % stériles
                    if i==6
                        rectangle('Position',[x_position_min Z_GS3(6)+0.15 x_position_max-1 (Z_GS3(3)+Z_GS3(2))/2-(Z_GS3(6)+0.15)],'FaceColor',C_anorthosite ,'LineWidth',1)
                    else
                        rectangle('Position',[x_position_min Z_GS3(6)+0.15 x_position_max-1 (Z_GS3(3)+Z_GS3(2))/2-(Z_GS3(6)+0.15)],'FaceColor',C_ilmenite ,'LineWidth',1)
                    end
                    % sable base
                    if i==6
                        rectangle('Position',[x_position_min 2.1-2 x_position_max-1 (Z_GS3(6)+0.15)-2.1+2],'FaceColor',C_sable ,'LineWidth',1)
                    else
                        rectangle('Position',[x_position_min Z_GS3(6)-0.15 x_position_max-1 (Z_GS3(6)+0.15)-(Z_GS3(6)-0.15)],'FaceColor',C_sable ,'LineWidth',1)
                    end
                end
                
                % GS3 legend (partie gauche de la figure)
                if data_GS3==1
                    for o=1
                        Z_GS3=GS3_location((i-1)*7+1:(i-1)*7+6,4);
                        if i==6
                            for k=1:6
                                plot(1.2,Z_GS3(k),'.b','Markersize',30)
                                text(1.2+0.15,Z_GS3(k)-0.001,NOM_SONDE_an{k},'Color','b','FontSize',11)
                            end
                        else
                            for k=1:6
                                plot(1.2,Z_GS3(k),'.b','Markersize',30)
                                text(1.2+0.15,Z_GS3(k)-0.001,NOM_SONDE{k},'Color','b','FontSize',11)
                            end
                        end
                    end
                end
                
                ylim([-0.2,6.5])
                
            end
        end
    end
    
    %% II - 10 Animation coupe 2D X et Y de la halde au cours du temps (VM)
    actif=1;
    time_to_plot=[241];
    for o=1
        if actif==1
            close all
            %% II - 10 a Données de la coupe 2D et histogramme
            for o=1
                Xmin_X=30;
                Xmax_X=90;
                Ymin_X=24.8;
                Ymax_X=25.2;
                Zmin=1.5;
                clear ELEMENT_SELECT
                ELEMENT_SELECT=Barycentre(find(Barycentre(:,2)>Xmin_X & Barycentre(:,2)<Xmax_X & Barycentre(:,3)>Ymin_X & Barycentre(:,3)<Ymax_X & Barycentre(:,4)>Zmin),:);
                % figure
                % plot3(ELEMENT_SELECT(:,2),ELEMENT_SELECT(:,3),ELEMENT_SELECT(:,4),'.k')
                
                Results_E4D_R_SELECT=[ELEMENT_SELECT,Results_E4D_R(ELEMENT_SELECT(:,1)+3,2:end-1)];
                
                Results_E4D_R_SELECT_log=Results_E4D_R_SELECT;
                Results_E4D_R_SELECT_log(:,5:end)=log(Results_E4D_R_SELECT_log(:,5:end));
                
                % Affichage de l'histogramme des données log
                figure('Color', [ 1 1 1])
                histogram(Results_E4D_R_SELECT_log(:,4:end),100)
                xlim([2 12])
                title('Histogramme de valeurs de résistivité (Ohm.m)','FontSize',16)
                xlabel('Valeur de résistivité en Ohm.m')
                ylabel('Nombre de valeurs dans chaque catégories')
                TicksM = [2;4;6;8;10;12;14;16];
                TicksL = round(exp(TicksM),0);
                ax = gca;
                ax.XTick=[2;4;6;8;10;12;14;16];
                ax.XTickLabel =round(exp(TicksM),0);
                grid
                grid minor
                
                % Troncature MIN au choix de l'utilisateur
                %                 p = get(gcf,'Position');
                %                 for o=1
                %                     d = dialog('Name','Choix de la valeur minimale de resistivité');
                %
                %                     txt = uicontrol('Parent',d,...
                %                         'Style','text',...
                %                         'Position',[100 200 210 80],...
                %                         'String',['Select the minimum resistivity value needed in Ohm.m (log values)'],...
                %                         'Fontsize',10);
                %
                %                     btn = uicontrol('Parent',d,...
                %                         'Position',[170 20 70 25],...
                %                         'String','Close',...
                %                         'Callback','delete(gcf)');
                %                 end % Dialog box
                %
                %                 CutOff_MIN=ginput(1);
                %                 CutOff_MIN=round(CutOff_MIN(:,1),2);
                CutOff_MIN=3.99;
                
                %                 % Troncature MAX au choix de l'utilisateur
                %                 p = get(gcf,'Position');
                %                 for o=1
                %                     d = dialog('Name','Choix de la valeur maximale de resistivité');
                %
                %                     txt = uicontrol('Parent',d,...
                %                         'Style','text',...
                %                         'Position',[100 200 210 80],...
                %                         'String',['Select the maximum resistivity value needed in Ohm.m (log values)'],...
                %                         'Fontsize',10);
                %
                %                     btn = uicontrol('Parent',d,...
                %                         'Position',[170 20 70 25],...
                %                         'String','Close',...
                %                         'Callback','delete(gcf)');
                %                 end % Dialog box
                %
                %                 CutOff_MAX=ginput(1);
                %                 CutOff_MAX=round(CutOff_MAX(:,1),2);
                CutOff_MAX=9.99;
                
                close
                % echelle de couleur de 0 a 1
                % echelle de valeur de R_min a R_max
                for i=5:length(Results_E4D_R_SELECT_log(1,:))
                    Results_E4D_R_SELECT_log(Results_E4D_R_SELECT_log(:,i)<=CutOff_MIN,i)=CutOff_MIN;
                    Results_E4D_R_SELECT_log(Results_E4D_R_SELECT_log(:,i)>=CutOff_MAX,i)=CutOff_MAX;
                    Results_E4D_R_SELECT_log(:,i)=Results_E4D_R_SELECT_log(:,i)-CutOff_MIN;
                    Results_E4D_R_SELECT_log(:,i)=round(Results_E4D_R_SELECT_log(:,i)/(CutOff_MAX-CutOff_MIN)*100);
                    Results_E4D_R_SELECT_log(Results_E4D_R_SELECT_log(:,i)==0,i)=1;
                end
            end
            
            %% II - 10 b MAILLAGE DE LA COUPE 2D et affichage
            for o=1
                
                p = get(gcf,'Position');
                set(0,'DefaultFigurePosition',p);
                close all
                pas_X=0.005;
                pas_Z=0.05;
                
                Zmax=9;
                [X_coupe_X,Z_coupe_X] = meshgrid(Xmin_X:pas_X:Xmax_X,Zmin:pas_Z:Zmax);
                
                % IMAGERIE AU COURS DU TEMPS
                for time_i=1:length(time_to_plot)%NB_INVERSIONS:NB_INVERSIONS
                    time=time_to_plot(time_i);
                    
                    figure('Color', [ 1 1 1])
                    
                    subplot(3,6,[1,2,3,4,5,6])
                    
                    
                    colormap ((jet(100)));
                    cmap = colormap;
                    
                    value = griddata(Results_E4D_R_SELECT_log(:,2),Results_E4D_R_SELECT_log(:,4),Results_E4D_R_SELECT_log(:,4+time),X_coupe_X,Z_coupe_X,'cubic');
                    
                    
                    pcolor(X_coupe_X,Z_coupe_X,value);
                    shading flat
                    hold on
                    contour(X_coupe_X,Z_coupe_X,value,5,'LineWidth',0.7,'LineColor','k')
                    
                    colormap ((jet(100)));
                    caxis([0 100]);
                    
                    
                    daspect([1,1,1])
                    
                    ylabel({'Z (m)'},'FontSize',12,'FontWeight','bold')
                    xlabel({'X (m)'},'FontSize',12,'FontWeight','bold')
                    
                    title(['Coupe 2D de la halde en Y = ',num2str((Ymin_X+Ymax_X)/2),' m le ',datestr(T_interp_2(time),'dd/mm'),' à ',datestr(T_interp_2(time),'HH'),'h',datestr(T_interp_2(time),'MM'),'      (RMS = 2.5%)'],'FontSize',14,'FontWeight','bold' )
                    
                    % Affichage des lignes de coupes en Y
                    for lysi=1:6
                        line([round(GS3_location((lysi-1)*7+1,2)) round(GS3_location((lysi-1)*7+1,2))],[Zmin GS3_location((lysi-1)*7+5,4)+0.15],'Color','w','linewidth',2)
                    end
                    
                    % AFFICHAGE DES COUPES EN Y EN PLUS
                    for o=1
                        for lysi=1:6
                            subplot(3,6,6+lysi)
                            for o=1
                                Xmin_Y=round(GS3_location((lysi-1)*7+1,2))-0.1;
                                Xmax_Y=round(GS3_location((lysi-1)*7+1,2))+0.1;
                                Ymin_Y=21;
                                Ymax_Y=31;
                                Zmin=1.5;
                                clear ELEMENT_SELECT_Y
                                ELEMENT_SELECT_Y=Barycentre(find(Barycentre(:,2)>Xmin_Y & Barycentre(:,2)<Xmax_Y & Barycentre(:,3)>Ymin_Y & Barycentre(:,3)<Ymax_Y & Barycentre(:,4)>Zmin),:);
                                % figure
                                % plot3(ELEMENT_SELECT(:,2),ELEMENT_SELECT(:,3),ELEMENT_SELECT(:,4),'.k')
                                
                                Results_E4D_R_SELECT_Y=[ELEMENT_SELECT_Y,Results_E4D_R(ELEMENT_SELECT_Y(:,1)+3,2:end-1)];
                                
                                Results_E4D_R_SELECT_log_Y=Results_E4D_R_SELECT_Y;
                                Results_E4D_R_SELECT_log_Y(:,5:end)=log(Results_E4D_R_SELECT_log_Y(:,5:end));
                                
                                % echelle de couleur de 0 a 1
                                % echelle de valeur de R_min a R_max
                                for i=5:length(Results_E4D_R_SELECT_log_Y(1,:))
                                    Results_E4D_R_SELECT_log_Y(Results_E4D_R_SELECT_log_Y(:,i)<=CutOff_MIN,i)=CutOff_MIN;
                                    Results_E4D_R_SELECT_log_Y(Results_E4D_R_SELECT_log_Y(:,i)>=CutOff_MAX,i)=CutOff_MAX;
                                    Results_E4D_R_SELECT_log_Y(:,i)=Results_E4D_R_SELECT_log_Y(:,i)-CutOff_MIN;
                                    Results_E4D_R_SELECT_log_Y(:,i)=round(Results_E4D_R_SELECT_log_Y(:,i)/(CutOff_MAX-CutOff_MIN)*100);
                                    Results_E4D_R_SELECT_log_Y(Results_E4D_R_SELECT_log_Y(:,i)==0,i)=1;
                                end
                            end
                            
                            %% II - 6 b MAILLAGE DE LA COUPE 2D et affichage
                            for o=1
                                pas_Y=0.005;
                                pas_Z=0.05;
                                
                                Zmax=9;
                                [Y_coupe_Y,Z_coupe_Y] = meshgrid(Ymin_Y:pas_Y:Ymax_Y,Zmin:pas_Z:Zmax);
                                
                                value_Y = griddata(Results_E4D_R_SELECT_log_Y(:,3),Results_E4D_R_SELECT_log_Y(:,4),Results_E4D_R_SELECT_log_Y(:,4+time),Y_coupe_Y,Z_coupe_Y,'cubic');
                                
                                
                                pcolor(Y_coupe_Y,Z_coupe_Y,value_Y);
                                shading flat
                                hold on
                                contour(Y_coupe_Y,Z_coupe_Y,value_Y,5,'LineWidth',0.7,'LineColor','k')
                                
                                
                                daspect([1,1,1])
                                
                                ylabel({'Z (m)'},'FontSize',12,'FontWeight','bold')
                                xlabel({'Y (m)'},'FontSize',12,'FontWeight','bold')
                                colormap ((jet(100)));
                                caxis([0 100]);
                                % position de la coupe en Y
                                line([(Ymin_X+Ymax_X)/2 (Ymin_X+Ymax_X)/2],[Zmin GS3_location((lysi-1)*7+5,4)+0.15],'Color','w','linewidth',2)
                                
                                % Affichage des sondes GS3
                                plot(GS3_location((lysi-1)*7+1:lysi*7,3),GS3_location((lysi-1)*7+1:lysi*7,4),'.w','Markersize',14);
                                title(['X = ',num2str((Xmin_Y+Xmax_Y)/2),' m'],'FontSize',14,'FontWeight','bold' )
                            end
                        end
                    end
                    
                    % AFFICHAGE LÉGENDE
                    for o=1
                        subplot(3,6,12+[1 2 3 4 5 6],'visible','off','xtick',[],'ytick',[],'Box','off')
                        
                        
                        
                        % Colorbar
                        % Légende
                        clear colorbar
                        colormap ((jet(100)));
                        colorbar;
                        caxis([0 100]);
                        TicksM = [1;20;40;60;80;100];
                        TicksL = round(exp((TicksM/100)*(CutOff_MAX-CutOff_MIN)+CutOff_MIN),0);
                        
                        
                        c=colorbar;
                        c.Label.String = 'Résistivité électrique (\Omega.m)';
                        c.Label.FontWeight='bold';
                        c.Label.FontSize=14;
                        c.Ticks=TicksM;
                        c.TickLabels={num2str(TicksL)};
                        %c.TickLabels.FontSize=12;
                        c.Location='north';
                        hold on
                    end
                    
                    % INDICATION DE TEMPS
                    for o=1
                        axes('Position',[.115 0.12 .79 .05],'Visible','on')
                        box off
                        %figure('color',[1 1 1])
                        hold on
                        T_injection=4.289279166666666e+04;
                        
                        
                        line([min(T_interp_2) max(T_interp_2)+1],[1 1],'Color','k','linewidth',2)
                        line([max(T_interp_2)+1-0.3 max(T_interp_2)+1],[1.05 1],'Color','k','linewidth',2)
                        line([max(T_interp_2)+1-0.3 max(T_interp_2)+1],[0.95 1],'Color','k','linewidth',2)
                        
                        
                        
                        hold on
                        plot(T_injection,1,'.b','markersize',50)
                        text(T_injection,1.1,'Essai d''infiltration')
                        plot(T_interp_2(time),1,'ok','markersize',10,'MarkerEdgeColor','w' ,'MarkerFaceColor',[0,0,0])
                        xlim([min(T_interp_2) max(T_interp_2)+1])
                        
                        
                        grid minor
                        ax = gca;
                        ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
                        ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
                        
                        set(gca,'ytick',[])
                        
                        
                    end
                end
            end
            
        end
    end
    
    %% II - 11 Animation coupe 2D X et Y de la résistivité électrique de l'eau dans la halde au cours du temps (VM)
    actif=1;
    time_to_plot=[48];
    for o=1
        if actif==1
            %% II - 11 a Traitement des données de résistivité de l'eau
            for o=1
                % INTERP SELON X
                for o=1
                    load DATA_RHO_W
                    
                    Z_init=8.4;
                    Z_end=5.7;
                    
                    d_Vect_X=1;
                    
                    Vect_X=(30:d_Vect_X:90)';
                    
                    DATA_RHO_W_INTERP=ones(1,length(DATA_RHO_W(1,:)));
                    for sonde=1:6
                        data_loc=DATA_RHO_W(sonde:7:6*7+sonde-1,:);
                        data_loc(end+1,:)=[0,30,data_loc(1,3:end)];
                        data_loc(end+1,:)=[0,90,data_loc(6,3:end)];
                        
                        z_interp=interp1(data_loc(:,2),data_loc(:,4),Vect_X);
                        clear MAT
                        MAT=[zeros(length(Vect_X),1),Vect_X,ones(length(Vect_X),1)*26,z_interp];
                        MAT=[MAT,zeros(length(Vect_X),length(DATA_RHO_W(1,:))-4)];
                        for col=5:length(DATA_RHO_W(1,:))
                            MAT(:,col)=interp1(data_loc(:,2),data_loc(:,col),Vect_X);
                        end
                        DATA_RHO_W_INTERP=[DATA_RHO_W_INTERP;MAT];
                    end
                    DATA_RHO_W_INTERP(1,:)=[];
                end
                
                % INTERP SELON Z
                for o=1
                    
                    d_Vect_Z=0.1;
                    
                    Vect_Z=(1.5:d_Vect_Z:9)';
                    
                    
                    DATA_RHO_W_INTERP_2=ones(1,length(DATA_RHO_W(1,:)));
                    
                    for xi=1:length(Vect_X)
                        data_loc=DATA_RHO_W_INTERP(DATA_RHO_W_INTERP(:,2)==Vect_X(xi),:);
                        data_loc(end+1,:)=[0,Vect_X(xi),26,data_loc(5,4)+0.15,data_loc(5,5:end)];
                        data_loc(end+1,:)=[0,Vect_X(xi),26,1.7,data_loc(6,5:end)];
                        
                        clear MAT
                        MAT=[zeros(length(Vect_Z),1),Vect_X(xi)*ones(length(Vect_Z),1),ones(length(Vect_Z),1)*26,Vect_Z];
                        MAT=[MAT,zeros(length(Vect_Z),length(DATA_RHO_W(1,:))-4)];
                        for col=5:length(DATA_RHO_W(1,:))
                            MAT(:,col)=interp1(data_loc(:,4),data_loc(:,col),Vect_Z);
                        end
                        DATA_RHO_W_INTERP_2=[DATA_RHO_W_INTERP_2;MAT];
                    end
                    DATA_RHO_W_INTERP_2(1,:)=[];
                end
                
            end
            close all
            
            %% II - 11 b Données de résistivité de l'eau de la coupe 2D et histogramme
            for o=1
                Xmin_X=30;
                Xmax_X=90;
                Ymin_X=24.8;
                Ymax_X=25.2;
                Zmin=1.5;
                
                
                clear DATA_W_log
                DATA_W_log=DATA_RHO_W_INTERP_2;
                DATA_W_log(:,5:end)=log(DATA_W_log(:,5:end));
                
                % Affichage de l'histogramme des données log de résistivité
                % électrique
                figure('Color', [ 1 1 1])
                histogram(DATA_W_log(:,5:end),100)
                xlim([-6 6])
                title('Histogramme de valeurs de résistivité de l''eau (Ohm.m)','FontSize',16)
                xlabel('Valeur de résistivité de l''eau en Ohm.m')
                ylabel('Nombre de valeurs dans chaque catégories')
                TicksM = [-6;-4;-2;0;2;4;6];
                TicksL = round(exp(TicksM),2);
                ax = gca;
                ax.XTick=TicksM;
                ax.XTickLabel =round(exp(TicksM),2);
                grid
                grid minor
                
                %                 % Troncature MIN au choix de l'utilisateur
                %                                 p = get(gcf,'Position');
                %                                 for o=1
                %                                     d = dialog('Name','Choix de la valeur minimale de resistivité');
                %
                %                                     txt = uicontrol('Parent',d,...
                %                                         'Style','text',...
                %                                         'Position',[100 200 210 80],...
                %                                         'String',['Select the minimum resistivity value needed in Ohm.m (log values)'],...
                %                                         'Fontsize',10);
                %
                %                                     btn = uicontrol('Parent',d,...
                %                                         'Position',[170 20 70 25],...
                %                                         'String','Close',...
                %                                         'Callback','delete(gcf)');
                %                                 end % Dialog box
                %
                %                                 CutOff_MIN=ginput(1);
                %                                 CutOff_MIN=round(CutOff_MIN(:,1),2);
                CutOff_MIN=0.45;
                
                %                 %                 % Troncature MAX au choix de l'utilisateur
                %                                 p = get(gcf,'Position');
                %                                 for o=1
                %                                     d = dialog('Name','Choix de la valeur maximale de resistivité');
                %
                %                                     txt = uicontrol('Parent',d,...
                %                                         'Style','text',...
                %                                         'Position',[100 200 210 80],...
                %                                         'String',['Select the maximum resistivity value needed in Ohm.m (log values)'],...
                %                                         'Fontsize',10);
                %
                %                                     btn = uicontrol('Parent',d,...
                %                                         'Position',[170 20 70 25],...
                %                                         'String','Close',...
                %                                         'Callback','delete(gcf)');
                %                                 end % Dialog box
                %
                %                                 CutOff_MAX=ginput(1);
                %                                 CutOff_MAX=round(CutOff_MAX(:,1),2);
                CutOff_MAX=5.69;
                
                close
                % echelle de couleur de 0 a 1
                % echelle de valeur de R_min a R_max
                for i=5:length(DATA_W_log(1,:))
                    DATA_W_log(DATA_W_log(:,i)<=CutOff_MIN,i)=CutOff_MIN;
                    DATA_W_log(DATA_W_log(:,i)>=CutOff_MAX,i)=CutOff_MAX;
                    DATA_W_log(:,i)=DATA_W_log(:,i)-CutOff_MIN;
                    DATA_W_log(:,i)=round(DATA_W_log(:,i)/(CutOff_MAX-CutOff_MIN)*100);
                    DATA_W_log(DATA_W_log(:,i)==0,i)=1;
                end
            end
            
            %% II - 1 c MAILLAGE DE LA COUPE 2D et affichage
            for o=1
                
                p = get(gcf,'Position');
                set(0,'DefaultFigurePosition',p);
                close all
                pas_X=0.005;
                pas_Z=0.05;
                
                Zmax=9;
                [X_coupe_X,Z_coupe_X] = meshgrid(Xmin_X:pas_X:Xmax_X,Zmin:pas_Z:Zmax);
                
                % IMAGERIE AU COURS DU TEMPS
                for time_i=1:length(time_to_plot)%NB_INVERSIONS:NB_INVERSIONS
                    time=time_to_plot(time_i);
                    
                    figure('Color', [ 1 1 1])
                    
                    subplot(3,6,[1,2,3,4,5,6])
                    
                    
                    colormap ((jet(100)));
                    cmap = colormap;
                    
                    value = griddata(DATA_W_log(:,2),DATA_W_log(:,4),DATA_W_log(:,4+time),X_coupe_X,Z_coupe_X,'linear');
                    
                    
                    pcolor(X_coupe_X,Z_coupe_X,value);
                    shading flat
                    hold on
                    contour(X_coupe_X,Z_coupe_X,value,5,'LineWidth',0.7,'LineColor','k')
                    
                    colormap ((jet(100)));
                    caxis([0 100]);
                    
                    
                    daspect([1,1,1])
                    
                    ylabel({'Z (m)'},'FontSize',12,'FontWeight','bold')
                    xlabel({'X (m)'},'FontSize',12,'FontWeight','bold')
                    
                    title(['Résistivité électrique de l''eau : Coupe 2D de la halde en Y = ',num2str((Ymin_X+Ymax_X)/2),' m le ',datestr(T_interp_2(time),'dd/mm'),' à ',datestr(T_interp_2(time),'HH'),'h',datestr(T_interp_2(time),'MM')],'FontSize',14,'FontWeight','bold' )
                    
                    % Affichage des lignes de coupes en Y
                    for lysi=1:6
                        line([round(GS3_location((lysi-1)*7+1,2)) round(GS3_location((lysi-1)*7+1,2))],[Zmin GS3_location((lysi-1)*7+5,4)+0.15],'Color','w','linewidth',2)
                    end
                    
                    % AFFICHAGE DES COUPES EN Y EN PLUS
                    for o=1
                        for lysi=1:6
                            subplot(3,6,6+lysi)
                            for o=1
                                Xmin_Y=round(GS3_location((lysi-1)*7+1,2))-0.1;
                                Xmax_Y=round(GS3_location((lysi-1)*7+1,2))+0.1;
                                Ymin_Y=21;
                                Ymax_Y=31;
                                Zmin=1.5;
                                
                                DATA_W_log_Y=DATA_W_log(DATA_W_log(:,2)==(Xmin_Y+Xmax_Y)/2,:);
                                DATA_W_log_Y(:,3)=ones(length(DATA_W_log_Y(:,1)),1)*21;
                                DATA_W_log_Y_2=DATA_W_log_Y;
                                DATA_W_log_Y_2(:,3)=ones(length(DATA_W_log_Y_2(:,1)),1)*31;
                                DATA_W_log_Y=[DATA_W_log_Y;DATA_W_log_Y_2];
                            end
                            
                            %% II - 6 b MAILLAGE DE LA COUPE 2D et affichage
                            for o=1
                                pas_Y=0.005;
                                pas_Z=0.05;
                                
                                Zmax=9;
                                [Y_coupe_Y,Z_coupe_Y] = meshgrid(Ymin_Y:pas_Y:Ymax_Y,Zmin:pas_Z:Zmax);
                                
                                value_Y = griddata(DATA_W_log_Y(:,3),DATA_W_log_Y(:,4),DATA_W_log_Y(:,4+time),Y_coupe_Y,Z_coupe_Y,'cubic');
                                
                                
                                pcolor(Y_coupe_Y,Z_coupe_Y,value_Y);
                                shading flat
                                hold on
                                contour(Y_coupe_Y,Z_coupe_Y,value_Y,5,'LineWidth',0.7,'LineColor','k')
                                
                                
                                daspect([1,1,1])
                                
                                ylabel({'Z (m)'},'FontSize',12,'FontWeight','bold')
                                xlabel({'Y (m)'},'FontSize',12,'FontWeight','bold')
                                colormap ((jet(100)));
                                caxis([0 100]);
                                % position de la coupe en Y
                                line([(Ymin_X+Ymax_X)/2 (Ymin_X+Ymax_X)/2],[Zmin GS3_location((lysi-1)*7+5,4)+0.15],'Color','w','linewidth',2)
                                
                                % Affichage des sondes GS3
                                plot(GS3_location((lysi-1)*7+1:lysi*7,3),GS3_location((lysi-1)*7+1:lysi*7,4),'.w','Markersize',14);
                                title(['X = ',num2str((Xmin_Y+Xmax_Y)/2),' m'],'FontSize',14,'FontWeight','bold' )
                            end
                        end
                    end
                    
                    % AFFICHAGE LÉGENDE
                    for o=1
                        subplot(3,6,12+[1 2 3 4 5 6],'visible','off','xtick',[],'ytick',[],'Box','off')
                        
                        
                        
                        % Colorbar
                        % Légende
                        clear colorbar
                        colormap ((jet(100)));
                        colorbar;
                        caxis([0 100]);
                        TicksM = [1;20;40;60;80;100];
                        TicksL = round(exp((TicksM/100)*(CutOff_MAX-CutOff_MIN)+CutOff_MIN),0);
                        
                        
                        c=colorbar;
                        c.Label.String = 'Résistivité électrique (\Omega.m)';
                        c.Label.FontWeight='bold';
                        c.Label.FontSize=14;
                        c.Ticks=TicksM;
                        c.TickLabels={num2str(TicksL)};
                        %c.TickLabels.FontSize=12;
                        c.Location='north';
                        hold on
                    end
                    
                    % INDICATION DE TEMPS
                    for o=1
                        axes('Position',[.115 0.12 .79 .05],'Visible','on')
                        box off
                        %figure('color',[1 1 1])
                        hold on
                        T_injection=4.289279166666666e+04;
                        
                        
                        line([min(T_interp_2) max(T_interp_2)+1],[1 1],'Color','k','linewidth',2)
                        line([max(T_interp_2)+1-0.3 max(T_interp_2)+1],[1.05 1],'Color','k','linewidth',2)
                        line([max(T_interp_2)+1-0.3 max(T_interp_2)+1],[0.95 1],'Color','k','linewidth',2)
                        
                        
                        
                        hold on
                        plot(T_injection,1,'.b','markersize',50)
                        text(T_injection,1.1,'Essai d''infiltration')
                        plot(T_interp_2(time),1,'ok','markersize',10,'MarkerEdgeColor','w' ,'MarkerFaceColor',[0,0,0])
                        xlim([min(T_interp_2) max(T_interp_2)+1])
                        
                        
                        grid minor
                        ax = gca;
                        ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
                        ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
                        
                        set(gca,'ytick',[])
                        
                        
                    end
                end
            end
            
        end
    end
    
    %% II - 12 Animation coupe 2D X et Y de RHO / RHO W au cours du temps (VM)
    actif=1;
    time_to_plot=[48];
    for o=1
        if actif==1
            close all
            %% II - 12 a Données de la coupe 2D et histogramme
            for o=1
                Xmin_X=30;
                Xmax_X=90;
                Ymin_X=24.8;
                Ymax_X=25.2;
                Zmin=1.5;
                
                % DATA DE RÉSISTIVITÉ E4D
                for o=1
                    clear ELEMENT_SELECT
                    ELEMENT_SELECT=Barycentre(find(Barycentre(:,2)>Xmin_X & Barycentre(:,2)<Xmax_X & Barycentre(:,3)>Ymin_X & Barycentre(:,3)<Ymax_X & Barycentre(:,4)>Zmin),:);
                    % figure
                    % plot3(ELEMENT_SELECT(:,2),ELEMENT_SELECT(:,3),ELEMENT_SELECT(:,4),'.k')
                    
                    Results_E4D_R_SELECT=[ELEMENT_SELECT,Results_E4D_R(ELEMENT_SELECT(:,1)+3,2:end-1)];
                end
                
                % DATA DE RÉSISTIVITÉ DE L'EAU
                for o=1
                    clear DATA_W
                    DATA_W=DATA_RHO_W_INTERP_2;
                end
            end
            
            %% II - 12 b MAILLAGE DE LA COUPE 2D et affichage en RHO / RHOW
            for o=1
                
                p = get(gcf,'Position');
                set(0,'DefaultFigurePosition',p);
                close all
                pas_X=0.005;
                pas_Z=0.05;
                
                Zmax=9;
                [X_coupe_X,Z_coupe_X] = meshgrid(Xmin_X:pas_X:Xmax_X,Zmin:pas_Z:Zmax);
                
                % IMAGERIE AU COURS DU TEMPS
                for time_i=1:length(time_to_plot)%NB_INVERSIONS:NB_INVERSIONS
                    time=time_to_plot(time_i);
                    % DATA DE RÉSISTIVITÉ E4D
                    for o=1
                        value_RHO = griddata(Results_E4D_R_SELECT(:,2),Results_E4D_R_SELECT(:,4),Results_E4D_R_SELECT(:,4+time),X_coupe_X,Z_coupe_X,'linear');
                        
                        % Pré-traitement
                        min_RHO=50;
                        max_RHO=22000;
                        
                        for i=1:length(value_RHO(1,:))
                            value_RHO(value_RHO(:,i)<min_RHO,i)=min_RHO;
                            value_RHO(value_RHO(:,i)>max_RHO,i)=max_RHO;
                        end
                    end
                    
                    % DATA DE RÉSISTIVITÉ EAU
                    for o=1
                        value_RHO_W = griddata(DATA_W(:,2),DATA_W(:,4),DATA_W(:,4+time),X_coupe_X,Z_coupe_X,'linear');
                        % Pré-traitement
                        min_RHO_W=2;
                        max_RHO_W=500;
                        
                        for i=1:length(value_RHO_W(1,:))
                            value_RHO_W(value_RHO_W(:,i)<min_RHO_W,i)=min_RHO_W;
                            value_RHO_W(value_RHO_W(:,i)>max_RHO_W,i)=max_RHO_W;
                        end
                    end
                    
                    % DATA DE RÉSISTIVITÉ E4D / RESISTIVITÉ EAU
                    value=value_RHO./value_RHO_W;
                    
                    % Affichage des coupes 2D
                    for o=1
                        figure('Color', [ 1 1 1])
                        
                        subplot(3,6,[1,2,3,4,5,6])
                        
                        
                        colormap ((jet(100)));
                        cmap = colormap;
                        
                        pcolor(X_coupe_X,Z_coupe_X,value);
                        shading flat
                        hold on
                        contour(X_coupe_X,Z_coupe_X,value,5,'LineWidth',0.7,'LineColor','k')
                        
                        colormap ((jet(100)));
                        caxis([0 300]);
                        
                        
                        daspect([1,1,1])
                        
                        ylabel({'Z (m)'},'FontSize',12,'FontWeight','bold')
                        xlabel({'X (m)'},'FontSize',12,'FontWeight','bold')
                        
                        title(['Coupe 2D de la halde en Y = ',num2str((Ymin_X+Ymax_X)/2),' m le ',datestr(T_interp_2(time),'dd/mm'),' à ',datestr(T_interp_2(time),'HH'),'h',datestr(T_interp_2(time),'MM'),'      (RMS = 2.5%)'],'FontSize',14,'FontWeight','bold' )
                        
                        % Affichage des lignes de coupes en Y
                        for lysi=1:6
                            line([round(GS3_location((lysi-1)*7+1,2)) round(GS3_location((lysi-1)*7+1,2))],[Zmin GS3_location((lysi-1)*7+5,4)+0.15],'Color','w','linewidth',2)
                        end
                        
                        % AFFICHAGE DES COUPES EN Y EN PLUS
                        for o=1
                            %                         for lysi=1:6
                            %                             subplot(3,6,6+lysi)
                            %                             for o=1
                            %                                 Xmin_Y=round(GS3_location((lysi-1)*7+1,2))-0.1;
                            %                                 Xmax_Y=round(GS3_location((lysi-1)*7+1,2))+0.1;
                            %                                 Ymin_Y=21;
                            %                                 Ymax_Y=31;
                            %                                 Zmin=1.5;
                            %                                 clear ELEMENT_SELECT_Y
                            %                                 ELEMENT_SELECT_Y=Barycentre(find(Barycentre(:,2)>Xmin_Y & Barycentre(:,2)<Xmax_Y & Barycentre(:,3)>Ymin_Y & Barycentre(:,3)<Ymax_Y & Barycentre(:,4)>Zmin),:);
                            %                                 % figure
                            %                                 % plot3(ELEMENT_SELECT(:,2),ELEMENT_SELECT(:,3),ELEMENT_SELECT(:,4),'.k')
                            %
                            %                                 Results_E4D_R_SELECT_Y=[ELEMENT_SELECT_Y,Results_E4D_R(ELEMENT_SELECT_Y(:,1)+3,2:end-1)];
                            %
                            %                                 Results_E4D_R_SELECT_log_Y=Results_E4D_R_SELECT_Y;
                            %                                 Results_E4D_R_SELECT_log_Y(:,5:end)=log(Results_E4D_R_SELECT_log_Y(:,5:end));
                            %
                            %                                 % echelle de couleur de 0 a 1
                            %                                 % echelle de valeur de R_min a R_max
                            %                                 for i=5:length(Results_E4D_R_SELECT_log_Y(1,:))
                            %                                     Results_E4D_R_SELECT_log_Y(Results_E4D_R_SELECT_log_Y(:,i)<=CutOff_MIN,i)=CutOff_MIN;
                            %                                     Results_E4D_R_SELECT_log_Y(Results_E4D_R_SELECT_log_Y(:,i)>=CutOff_MAX,i)=CutOff_MAX;
                            %                                     Results_E4D_R_SELECT_log_Y(:,i)=Results_E4D_R_SELECT_log_Y(:,i)-CutOff_MIN;
                            %                                     Results_E4D_R_SELECT_log_Y(:,i)=round(Results_E4D_R_SELECT_log_Y(:,i)/(CutOff_MAX-CutOff_MIN)*100);
                            %                                     Results_E4D_R_SELECT_log_Y(Results_E4D_R_SELECT_log_Y(:,i)==0,i)=1;
                            %                                 end
                            %                             end
                            %
                            %                             %% II - 6 b MAILLAGE DE LA COUPE 2D et affichage
                            %                             for o=1
                            %                                 pas_Y=0.005;
                            %                                 pas_Z=0.05;
                            %
                            %                                 Zmax=9;
                            %                                 [Y_coupe_Y,Z_coupe_Y] = meshgrid(Ymin_Y:pas_Y:Ymax_Y,Zmin:pas_Z:Zmax);
                            %
                            %                                 value_Y = griddata(Results_E4D_R_SELECT_log_Y(:,3),Results_E4D_R_SELECT_log_Y(:,4),Results_E4D_R_SELECT_log_Y(:,4+time),Y_coupe_Y,Z_coupe_Y,'cubic');
                            %
                            %
                            %                                 pcolor(Y_coupe_Y,Z_coupe_Y,value_Y);
                            %                                 shading flat
                            %                                 hold on
                            %                                 contour(Y_coupe_Y,Z_coupe_Y,value_Y,5,'LineWidth',0.7,'LineColor','k')
                            %
                            %
                            %                                 daspect([1,1,1])
                            %
                            %                                 ylabel({'Z (m)'},'FontSize',12,'FontWeight','bold')
                            %                                 xlabel({'Y (m)'},'FontSize',12,'FontWeight','bold')
                            %                                 colormap ((jet(100)));
                            %                                 caxis([0 100]);
                            %                                 % position de la coupe en Y
                            %                                 line([(Ymin_X+Ymax_X)/2 (Ymin_X+Ymax_X)/2],[Zmin GS3_location((lysi-1)*7+5,4)+0.15],'Color','w','linewidth',2)
                            %
                            %                                 % Affichage des sondes GS3
                            %                                 plot(GS3_location((lysi-1)*7+1:lysi*7,3),GS3_location((lysi-1)*7+1:lysi*7,4),'.w','Markersize',14);
                            %                                 title(['X = ',num2str((Xmin_Y+Xmax_Y)/2),' m'],'FontSize',14,'FontWeight','bold' )
                            %                             end
                            %                         end
                            %                     end
                            %
                            %                     % AFFICHAGE LÉGENDE
                            %                     for o=1
                            %                         subplot(3,6,12+[1 2 3 4 5 6],'visible','off','xtick',[],'ytick',[],'Box','off')
                            %
                            %
                            %
                            %                         % Colorbar
                            %                         % Légende
                            %                         clear colorbar
                            %                         colormap ((jet(100)));
                            %                         colorbar;
                            %                         caxis([0 100]);
                            %                         TicksM = [1;20;40;60;80;100];
                            %                         TicksL = round(exp((TicksM/100)*(CutOff_MAX-CutOff_MIN)+CutOff_MIN),0);
                            %
                            %
                            %                         c=colorbar;
                            %                         c.Label.String = 'Résistivité électrique (\Omega.m)';
                            %                         c.Label.FontWeight='bold';
                            %                         c.Label.FontSize=14;
                            %                         c.Ticks=TicksM;
                            %                         c.TickLabels={num2str(TicksL)};
                            %                         %c.TickLabels.FontSize=12;
                            %                         c.Location='north';
                            %                         hold on
                        end
                        %
                        % INDICATION DE TEMPS
                        for o=1
                            axes('Position',[.115 0.12 .79 .05],'Visible','on')
                            box off
                            %figure('color',[1 1 1])
                            hold on
                            T_injection=4.289279166666666e+04;
                            
                            
                            line([min(T_interp_2) max(T_interp_2)+1],[1 1],'Color','k','linewidth',2)
                            line([max(T_interp_2)+1-0.3 max(T_interp_2)+1],[1.05 1],'Color','k','linewidth',2)
                            line([max(T_interp_2)+1-0.3 max(T_interp_2)+1],[0.95 1],'Color','k','linewidth',2)
                            
                            
                            
                            hold on
                            plot(T_injection,1,'.b','markersize',50)
                            text(T_injection,1.1,'Essai d''infiltration')
                            plot(T_interp_2(time),1,'ok','markersize',10,'MarkerEdgeColor','w' ,'MarkerFaceColor',[0,0,0])
                            xlim([min(T_interp_2) max(T_interp_2)+1])
                            
                            
                            grid minor
                            ax = gca;
                            ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
                            ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
                            
                            set(gca,'ytick',[])
                            
                            
                        end
                    end
                end
            end
        end
    end
    
    %% II - 13 Superposition E4D EAU et RAPPORT
    actif=1;
    time_to_plot=[74];
    for o=1
        %% II - 13 a Animation coupe 2D X et Y de la halde au cours du temps (VM)
        for o=1
            if actif==1
                close all
                %% II - 13 a i Données de la coupe 2D et histogramme RES
                for o=1
                    Xmin_X=30;
                    Xmax_X=90;
                    Ymin_X=24.8;
                    Ymax_X=25.2;
                    Zmin=1.5;
                    clear ELEMENT_SELECT
                    ELEMENT_SELECT=Barycentre(find(Barycentre(:,2)>Xmin_X & Barycentre(:,2)<Xmax_X & Barycentre(:,3)>Ymin_X & Barycentre(:,3)<Ymax_X & Barycentre(:,4)>Zmin),:);
                    
                    Results_E4D_R_SELECT=[ELEMENT_SELECT,Results_E4D_R(ELEMENT_SELECT(:,1)+3,2:end-1)];
                    
                    Results_E4D_R_SELECT_log=Results_E4D_R_SELECT;
                    Results_E4D_R_SELECT_log(:,5:end)=log(Results_E4D_R_SELECT_log(:,5:end));
                    
                    
                    CutOff_MIN_R=3.99;
                    CutOff_MAX_R=9.99;
                    
                    close
                    % echelle de couleur de 0 a 1
                    % echelle de valeur de R_min a R_max
                    for i=5:length(Results_E4D_R_SELECT_log(1,:))
                        Results_E4D_R_SELECT_log(Results_E4D_R_SELECT_log(:,i)<=CutOff_MIN_R,i)=CutOff_MIN_R;
                        Results_E4D_R_SELECT_log(Results_E4D_R_SELECT_log(:,i)>=CutOff_MAX_R,i)=CutOff_MAX_R;
                        Results_E4D_R_SELECT_log(:,i)=Results_E4D_R_SELECT_log(:,i)-CutOff_MIN_R;
                        Results_E4D_R_SELECT_log(:,i)=round(Results_E4D_R_SELECT_log(:,i)/(CutOff_MAX_R-CutOff_MIN_R)*100);
                        Results_E4D_R_SELECT_log(Results_E4D_R_SELECT_log(:,i)==0,i)=1;
                    end
                end
                
                %% II - 13 a ii Traitement des données de résistivité de l'eau RES EAU
                for o=1
                    load DATA_RHO_W_INTERP_2
                    
                    clear DATA_W_log
                    DATA_W_log=DATA_RHO_W_INTERP_2;
                    DATA_W_log(:,5:end)=log(DATA_W_log(:,5:end));
                    
                    CutOff_MIN_W=0.45;
                    CutOff_MAX_W=5.69;
                    
                    % echelle de couleur de 0 a 1
                    % echelle de valeur de R_min a R_max
                    for i=5:length(DATA_W_log(1,:))
                        DATA_W_log(DATA_W_log(:,i)<=CutOff_MIN_W,i)=CutOff_MIN_W;
                        DATA_W_log(DATA_W_log(:,i)>=CutOff_MAX_W,i)=CutOff_MAX_W;
                        DATA_W_log(:,i)=DATA_W_log(:,i)-CutOff_MIN_W;
                        DATA_W_log(:,i)=round(DATA_W_log(:,i)/(CutOff_MAX_W-CutOff_MIN_W)*100);
                        DATA_W_log(DATA_W_log(:,i)==0,i)=1;
                    end
                end
                
                %% II - 13 a iii Données pour le rapport
                for o=1
                    % DATA DE RÉSISTIVITÉ E4D
                    for o=1
                        clear ELEMENT_SELECT
                        ELEMENT_SELECT=Barycentre(find(Barycentre(:,2)>Xmin_X & Barycentre(:,2)<Xmax_X & Barycentre(:,3)>Ymin_X & Barycentre(:,3)<Ymax_X & Barycentre(:,4)>Zmin),:);
                        % figure
                        % plot3(ELEMENT_SELECT(:,2),ELEMENT_SELECT(:,3),ELEMENT_SELECT(:,4),'.k')
                        
                        Results_E4D_R_SELECT=[ELEMENT_SELECT,Results_E4D_R(ELEMENT_SELECT(:,1)+3,2:end-1)];
                    end
                    
                    % DATA DE RÉSISTIVITÉ DE L'EAU
                    for o=1
                        clear DATA_W
                        DATA_W=DATA_RHO_W_INTERP_2;
                    end
                end
            end
        end
        
        %% II - 13 b MAILLAGE DE LA COUPE 2D et affichage
        for o=1
            
            p = get(gcf,'Position');
            set(0,'DefaultFigurePosition',p);
            
            % Maillage
            pas_X=0.005;
            pas_Z=0.05;
            
            Zmax=9;
            [X_coupe_X,Z_coupe_X] = meshgrid(Xmin_X:pas_X:Xmax_X,Zmin:pas_Z:Zmax);
            
            % IMAGERIE AU COURS DU TEMPS
            for time_i=1:length(time_to_plot)%NB_INVERSIONS:NB_INVERSIONS
                time=time_to_plot(time_i);
                
                figure('Color', [ 1 1 1])
                
                subplot(3,1,1)
                % AFFICHAGE RESISTIVITÉ E4D
                for o=1
                    colormap ((jet(100)));
                    cmap = colormap;
                    
                    value = griddata(Results_E4D_R_SELECT_log(:,2),Results_E4D_R_SELECT_log(:,4),Results_E4D_R_SELECT_log(:,4+time),X_coupe_X,Z_coupe_X,'cubic');
                    
                    
                    pcolor(X_coupe_X,Z_coupe_X,value);
                    shading flat
                    hold on
                    contour(X_coupe_X,Z_coupe_X,value,5,'LineWidth',0.7,'LineColor','k')
                    
                    colormap ((jet(100)));
                    caxis([0 100]);
                    
                    
                    daspect([1,1,1])
                    
                    ylabel({'Z (m)'},'FontSize',12,'FontWeight','bold')
                    xlabel({'X (m)'},'FontSize',12,'FontWeight','bold')
                    
                    title(['Coupe 2D de la halde en Y = ',num2str((Ymin_X+Ymax_X)/2),' m le ',datestr(T_interp_2(time),'dd/mm'),' à ',datestr(T_interp_2(time),'HH'),'h',datestr(T_interp_2(time),'MM'),'      (RMS = 2.5%)'],'FontSize',14,'FontWeight','bold' )
                    
                    % AFFICHAGE LÉGENDE
                    for o=1
                        
                        % Colorbar
                        % Légende
                        clear colorbar
                        colormap ((jet(100)));
                        colorbar;
                        caxis([0 100]);
                        TicksM = [1;20;40;60;80;100];
                        TicksL = round(exp((TicksM/100)*(CutOff_MAX_R-CutOff_MIN_R)+CutOff_MIN_R),0);
                        
                        
                        c=colorbar;
                        c.Label.String = {'\rho_E_4_D', '(\Omega.m)'};
                        c.Label.FontWeight='bold';
                        c.Label.FontSize=14;
                        c.Ticks=TicksM;
                        c.TickLabels={num2str(TicksL)};
                        %c.TickLabels.FontSize=12;
                        c.Location='eastoutside';
                        hold on
                    end
                end
                
                subplot(3,1,2)
                % AFFICHAGE RESISTIVITÉ EAU
                for o=1
                    colormap ((jet(100)));
                    cmap = colormap;
                    
                    value = griddata(DATA_W_log(:,2),DATA_W_log(:,4),DATA_W_log(:,4+time),X_coupe_X,Z_coupe_X,'linear');
                    
                    
                    pcolor(X_coupe_X,Z_coupe_X,value);
                    shading flat
                    hold on
                    contour(X_coupe_X,Z_coupe_X,value,5,'LineWidth',0.7,'LineColor','k')
                    
                    colormap ((jet(100)));
                    caxis([0 100]);
                    
                    
                    daspect([1,1,1])
                    
                    ylabel({'Z (m)'},'FontSize',12,'FontWeight','bold')
                    xlabel({'X (m)'},'FontSize',12,'FontWeight','bold')
                    
                    title(['Résistivité électrique de l''eau : Coupe 2D de la halde en Y = ',num2str((Ymin_X+Ymax_X)/2),' m le ',datestr(T_interp_2(time),'dd/mm'),' à ',datestr(T_interp_2(time),'HH'),'h',datestr(T_interp_2(time),'MM')],'FontSize',14,'FontWeight','bold' )
                    
                    
                    % AFFICHAGE LÉGENDE
                    for o=1
                        
                        % Colorbar
                        % Légende
                        clear colorbar
                        colormap ((jet(100)));
                        colorbar;
                        caxis([0 100]);
                        TicksM = [1;20;40;60;80;100];
                        TicksL = round(exp((TicksM/100)*(CutOff_MAX_W-CutOff_MIN_W)+CutOff_MIN_W),0);
                        
                        
                        c=colorbar;
                        c.Label.String = {'\rho_w', '(\Omega.m)'};
                        c.Label.FontWeight='bold';
                        c.Label.FontSize=14;
                        c.Ticks=TicksM;
                        c.TickLabels={num2str(TicksL)};
                        %c.TickLabels.FontSize=12;
                        c.Location='eastoutside';
                        hold on
                    end
                end
                
                subplot(3,1,3)
                % AFFICHAGE RAPPORT RESISTIVITÉ
                for o=1
                    % Traitement data
                    % DATA DE RÉSISTIVITÉ E4D
                    for o=1
                        value_RHO = griddata(Results_E4D_R_SELECT(:,2),Results_E4D_R_SELECT(:,4),Results_E4D_R_SELECT(:,4+time),X_coupe_X,Z_coupe_X,'linear');
                        
                        % Pré-traitement
                        min_RHO=50;
                        max_RHO=22000;
                        
                        for i=1:length(value_RHO(1,:))
                            value_RHO(value_RHO(:,i)<min_RHO,i)=min_RHO;
                            value_RHO(value_RHO(:,i)>max_RHO,i)=max_RHO;
                        end
                    end
                    
                    % DATA DE RÉSISTIVITÉ EAU
                    for o=1
                        value_RHO_W = griddata(DATA_W(:,2),DATA_W(:,4),DATA_W(:,4+time),X_coupe_X,Z_coupe_X,'linear');
                        % Pré-traitement
                        min_RHO_W=2;
                        max_RHO_W=500;
                        
                        for i=1:length(value_RHO_W(1,:))
                            value_RHO_W(value_RHO_W(:,i)<min_RHO_W,i)=min_RHO_W;
                            value_RHO_W(value_RHO_W(:,i)>max_RHO_W,i)=max_RHO_W;
                        end
                    end
                    
                    % DATA DE RÉSISTIVITÉ E4D / RESISTIVITÉ EAU
                    value=value_RHO./value_RHO_W;
                    
                    colormap ((jet(100)));
                    cmap = colormap;
                    
                    pcolor(X_coupe_X,Z_coupe_X,value);
                    shading flat
                    hold on
                    contour(X_coupe_X,Z_coupe_X,value,5,'LineWidth',0.7,'LineColor','k')
                    
                    colormap ((jet(100)));
                    caxis([0 300]);
                    
                    
                    daspect([1,1,1])
                    
                    ylabel({'Z (m)'},'FontSize',12,'FontWeight','bold')
                    xlabel({'X (m)'},'FontSize',12,'FontWeight','bold')
                    
                    title(['RAPPORT DE RÉSISTIVITÉS : Coupe 2D de la halde en Y = ',num2str((Ymin_X+Ymax_X)/2),' m le ',datestr(T_interp_2(time),'dd/mm'),' à ',datestr(T_interp_2(time),'HH'),'h',datestr(T_interp_2(time),'MM'),'      (RMS = 2.5%)'],'FontSize',14,'FontWeight','bold' )
                    
                    % AFFICHAGE LÉGENDE
                    for o=1
                        
                        % Colorbar
                        % Légende
                        clear colorbar
                        colormap ((jet(100)));
                        colorbar;
                        caxis([0 100]);
                        TicksM = [1;20;40;60;80;100];
                        TicksL = round(exp((TicksM/100)*(CutOff_MAX-CutOff_MIN)+CutOff_MIN),0);
                        
                        
                        c=colorbar;
                        c.Label.String = {'\rho_E_4_D / \rho_w', '(\Omega.m)'};
                        c.Label.FontWeight='bold';
                        c.Label.FontSize=14;
                        c.Ticks=TicksM;
                        c.TickLabels={num2str(TicksL)};
                        %c.TickLabels.FontSize=12;
                        c.Location='eastoutside';
                        hold on
                    end
                end
                
                % INDICATION DE TEMPS
                for o=1
                    axes('Position',[.115 0.12 .79 .05],'Visible','on')
                    box off
                    %figure('color',[1 1 1])
                    hold on
                    T_injection=4.289279166666666e+04;
                    
                    
                    line([min(T_interp_2) max(T_interp_2)+1],[1 1],'Color','k','linewidth',2)
                    line([max(T_interp_2)+1-0.3 max(T_interp_2)+1],[1.05 1],'Color','k','linewidth',2)
                    line([max(T_interp_2)+1-0.3 max(T_interp_2)+1],[0.95 1],'Color','k','linewidth',2)
                    
                    
                    
                    hold on
                    plot(T_injection,1,'.b','markersize',50)
                    text(T_injection,1.1,'Essai d''infiltration')
                    plot(T_interp_2(time),1,'ok','markersize',10,'MarkerEdgeColor','w' ,'MarkerFaceColor',[0,0,0])
                    xlim([min(T_interp_2) max(T_interp_2)+1])
                    
                    
                    grid minor
                    ax = gca;
                    ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
                    ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
                    
                    set(gca,'ytick',[])
                    
                    
                end
            end
        end
    end
    
    %% II - 14 Animation coupe 2D X et Y de la halde au cours du temps => VARIATIONS
    actif=1;
    time_to_plot=[20;40;50;51;52;53;54;55;56;57;58;60;70;80;100;120;150;200;241];
    %time_to_plot=[20;40;50;51;52;53;54];
    %time_to_plot=[60];
    time_to_plot=time_to_plot+1;
    for o=1
        if actif==1
            close all
            %% II - 12 a Données de la coupe 2D et histogramme
            for o=1
                Xmin_X=30;
                Xmax_X=90;
                Ymin_X=24.8;
                Ymax_X=25.2;
                Zmin=1.5;
                
                % DATA RÉSISTIVITÉ
                for o=1
                    clear ELEMENT_SELECT
                    ELEMENT_SELECT=Barycentre(find(Barycentre(:,2)>Xmin_X & Barycentre(:,2)<Xmax_X & Barycentre(:,3)>Ymin_X & Barycentre(:,3)<Ymax_X & Barycentre(:,4)>Zmin),:);
                    % figure
                    % plot3(ELEMENT_SELECT(:,2),ELEMENT_SELECT(:,3),ELEMENT_SELECT(:,4),'.k')
                    
                    Results_E4D_R_SELECT=[ELEMENT_SELECT,Results_E4D_R(ELEMENT_SELECT(:,1)+3,2:end-1)];
                    
                    Results_E4D_R_SELECT_log=Results_E4D_R_SELECT;
                    Results_E4D_R_SELECT_log(:,5:end)=log(Results_E4D_R_SELECT_log(:,5:end));
                    
                    
                    CutOff_MIN=3.99;
                    
                    CutOff_MAX=9.99;
                    
                    close
                    % echelle de couleur de 0 a 1
                    % echelle de valeur de R_min a R_max
                    for i=5:length(Results_E4D_R_SELECT_log(1,:))
                        Results_E4D_R_SELECT_log(Results_E4D_R_SELECT_log(:,i)<=CutOff_MIN,i)=CutOff_MIN;
                        Results_E4D_R_SELECT_log(Results_E4D_R_SELECT_log(:,i)>=CutOff_MAX,i)=CutOff_MAX;
                        Results_E4D_R_SELECT_log(:,i)=Results_E4D_R_SELECT_log(:,i)-CutOff_MIN;
                        Results_E4D_R_SELECT_log(:,i)=round(Results_E4D_R_SELECT_log(:,i)/(CutOff_MAX-CutOff_MIN)*100);
                        Results_E4D_R_SELECT_log(Results_E4D_R_SELECT_log(:,i)==0,i)=1;
                    end
                end
                
                % DATA VARIATIONS
                for o=1
                    Res_init=[ELEMENT_SELECT,Results_E4D_R(ELEMENT_SELECT(:,1)+3,2:50)];
                    
                    % Valeurs initiales, minimales et maximales de résistivité
                    Results_E4D_R_SELECT_init_min_max=[ELEMENT_SELECT,zeros(length(ELEMENT_SELECT),3)];
                    for i=1:length(Res_init)
                        % initiale
                        Results_E4D_R_SELECT_init_min_max(i,5)=median(Res_init(i,5:end));
                        % min
                        Results_E4D_R_SELECT_init_min_max(i,6)=min(Results_E4D_R_SELECT(i,5:end));
                        % max
                        Results_E4D_R_SELECT_init_min_max(i,7)=max(Results_E4D_R_SELECT(i,5:end));
                    end
                    
                    % Matrice de valeurs pour les variations en % PAR
                    % RAPPORT AU DÉBUT NORMALISÉ
                    for o=1
                        %                         Results_E4D_R_SELECT_VAR=ELEMENT_SELECT;
                        %                         for i=5:length(Results_E4D_R_SELECT(1,:))
                        %                             mat=Results_E4D_R_SELECT(:,i);
                        %                             mat_sign=mat-Results_E4D_R_SELECT_init_min_max(:,5);
                        %                             mat_sign=mat_sign./abs(mat_sign);
                        %                             mat_2=mat_sign;
                        %                             for j=1:length(mat_sign)
                        %                                 if mat_sign(j)>0 % augmentation
                        %                                     mat_2(j)=(mat(j)-Results_E4D_R_SELECT_init_min_max(j,5))*100/(Results_E4D_R_SELECT_init_min_max(j,7)-Results_E4D_R_SELECT_init_min_max(j,5));
                        %                                 else
                        %                                     mat_2(j)=-(Results_E4D_R_SELECT_init_min_max(j,5)-mat(j))*100/(Results_E4D_R_SELECT_init_min_max(j,5)-Results_E4D_R_SELECT_init_min_max(j,6));
                        %                                 end
                        %                             end
                        %                             Results_E4D_R_SELECT_VAR=[Results_E4D_R_SELECT_VAR,mat_2];
                        %                         end
                    end
                    
                    % Matrice de valeurs pour les variations en % PAR
                    % RAPPORT A L'IMAGE INITIALE
                    for o=1
                        %                         Results_E4D_R_SELECT_VAR=ELEMENT_SELECT;
                        %                         for i=6:length(Results_E4D_R_SELECT(1,:))
                        %                             mat=Results_E4D_R_SELECT(:,i);
                        %                             mat_sign=mat-Results_E4D_R_SELECT(:,i-1);
                        %                             mat_sign=mat_sign./abs(mat_sign);
                        %                             mat_2=mat_sign;
                        %                             for j=1:length(mat_sign)
                        %                                 if mat_sign(j)>0 % augmentation
                        %                                     mat_2(j)=(mat(j)-Results_E4D_R_SELECT(j,i-1))*100/(Results_E4D_R_SELECT_init_min_max(j,7)-Results_E4D_R_SELECT_init_min_max(j,5));
                        %                                 else
                        %                                     mat_2(j)=-(Results_E4D_R_SELECT(j,i-1)-mat(j))*100/(Results_E4D_R_SELECT_init_min_max(j,5)-Results_E4D_R_SELECT_init_min_max(j,6));
                        %                                 end
                        %                             end
                        %                             Results_E4D_R_SELECT_VAR=[Results_E4D_R_SELECT_VAR,-mat_2];
                        %                         end
                    end
                    
                    % Matrice de valeurs pour les variations en % PAR
                    % RAPPORT AU DÉBUT NON NORMALISÉ
                    for o=1
                        %                         Results_E4D_R_SELECT_VAR=ELEMENT_SELECT;
                        %                         for i=5:length(Results_E4D_R_SELECT(1,:))
                        %                             mat=Results_E4D_R_SELECT(:,i);
                        %                             mat_2=(mat-Results_E4D_R_SELECT_init_min_max(:,5))*100./Results_E4D_R_SELECT_init_min_max(:,5);
                        %                             Results_E4D_R_SELECT_VAR=[Results_E4D_R_SELECT_VAR,mat_2];
                        %                         end
                    end
                    
                    % Matrice de valeurs pour les variations en % PAR
                    % RAPPORT A L'IMAGE INITIALE EN BINAIRE
                    for o=1
                        Results_E4D_R_SELECT_VAR=ELEMENT_SELECT;
                        for i=6:length(Results_E4D_R_SELECT(1,:))
                            mat=Results_E4D_R_SELECT(:,i);
                            mat_sign=100*(mat-Results_E4D_R_SELECT_init_min_max(:,5));
                            
                            Results_E4D_R_SELECT_VAR=[Results_E4D_R_SELECT_VAR,mat_sign];
                        end
                    end
                    
                end
                
            end
            
            %% II - 12 b MAILLAGE DE LA COUPE 2D et affichage en RHO / VAR de RHO
            for o=1
                
                p = get(gcf,'Position');
                set(0,'DefaultFigurePosition',p);
                close all
                pas_X=0.005;
                pas_Z=0.05;
                
                Zmax=9;
                [X_coupe_X,Z_coupe_X] = meshgrid(Xmin_X:pas_X:Xmax_X,Zmin:pas_Z:Zmax);
                
                % IMAGERIE AU COURS DU TEMPS
                for time_i=1:length(time_to_plot)%NB_INVERSIONS:NB_INVERSIONS
                    time=time_to_plot(time_i);
                    
                    % Affichage des coupes 2D
                    for o=1
                        figure('Color', [ 1 1 1])
                        
                        % SUBPLOT DES RÉSISTIVITÉS
                        for o=1
                            ax1=subplot(2,1,1);
                            
                            DATA_RES=griddata(Results_E4D_R_SELECT_log(:,2),Results_E4D_R_SELECT_log(:,4),Results_E4D_R_SELECT_log(:,4+time),X_coupe_X,Z_coupe_X,'linear');
                            value =DATA_RES;
                            
                            colormap(ax1,jet(100))
                            
                            pcolor(X_coupe_X,Z_coupe_X,value);
                            shading flat
                            hold on
                            contour(X_coupe_X,Z_coupe_X,value,5,'LineWidth',0.7,'LineColor','k')
                            
                            caxis([0 100]);
                            
                            
                            daspect([1,1,1])
                            
                            ylabel({'Z (m)'},'FontSize',12,'FontWeight','bold')
                            xlabel({'X (m)'},'FontSize',12,'FontWeight','bold')
                            
                            title(['Coupe 2D de résistivités de la halde en Y = ',num2str((Ymin_X+Ymax_X)/2),' m le ',datestr(T_interp_2(time),'dd/mm'),' à ',datestr(T_interp_2(time),'HH'),'h',datestr(T_interp_2(time),'MM'),'      (RMS = 2.5%)'],'FontSize',14,'FontWeight','bold' )
                            
                            % AFFICHAGE LÉGENDE
                            for o=1
                                
                                % Colorbar
                                % Légende
                                colormap(ax1,jet(100))
                                colorbar;
                                caxis([0 100]);
                                TicksM = [1;20;40;60;80;100];
                                TicksL = round(exp((TicksM/100)*(CutOff_MAX-CutOff_MIN)+CutOff_MIN),0);
                                
                                
                                c=colorbar;
                                c.Label.String = 'Résistivité électrique (\Omega.m)';
                                c.Label.FontWeight='bold';
                                c.Label.FontSize=14;
                                c.Ticks=TicksM;
                                c.TickLabels={num2str(TicksL)};
                                %c.TickLabels.FontSize=12;
                                c.Location='southoutside';
                                hold on
                            end
                        end
                        
                        % SUBPLOT DES VARIATIONS DE RÉSISTIVITÉS
                        for o=1
                            ax2=subplot(2,1,2);
                            
                            DATA_VAR_RES=griddata(Results_E4D_R_SELECT_VAR(:,2),Results_E4D_R_SELECT_VAR(:,4),Results_E4D_R_SELECT_VAR(:,4+time),X_coupe_X,Z_coupe_X,'linear');
                            value =DATA_VAR_RES;
                            
                            
                            pcolor(X_coupe_X,Z_coupe_X,value);
                            shading flat
                            hold on
                            %contour(X_coupe_X,Z_coupe_X,value,5,'LineWidth',0.7,'LineColor','k')
                            
                            colormap(ax2,redblue(100))
                            caxis([-100 100]);
                            
                            
                            daspect([1,1,1])
                            
                            ylabel({'Z (m)'},'FontSize',12,'FontWeight','bold')
                            xlabel({'X (m)'},'FontSize',12,'FontWeight','bold')
                            
                            title(['Coupe 2D des variations de résistivité de la halde en Y = ',num2str((Ymin_X+Ymax_X)/2),' m le ',datestr(T_interp_2(time),'dd/mm'),' à ',datestr(T_interp_2(time),'HH'),'h',datestr(T_interp_2(time),'MM'),'      (RMS = 2.5%)'],'FontSize',14,'FontWeight','bold' )
                            
                            
                            % AFFICHAGE LÉGENDE
                            for o=1
                                
                                % Colorbar
                                % Légende
                                colormap(ax2,redblue(100))
                                
                                colorbar;
                                caxis([-100 100]);
                                TicksM = [-100;-75;-50;-25;0;25;50;75;100];
                                TicksL = TicksM;
                                
                                
                                c=colorbar;
                                c.Label.String = 'Variation de résistivité par rapport à l''image initiale (%)';
                                c.Label.FontWeight='bold';
                                c.Label.FontSize=14;
                                c.Ticks=TicksM;
                                c.TickLabels={num2str(TicksL)};
                                %c.TickLabels.FontSize=12;
                                c.Location='southoutside';
                                hold on
                            end
                        end
                        
                        % INDICATION DE TEMPS
                        for o=1
                            axes('Position',[.115 0.035 .79 .05],'Visible','on')
                            box off
                            %figure('color',[1 1 1])
                            hold on
                            T_injection=4.289279166666666e+04;
                            
                            
                            line([min(T_interp_2) max(T_interp_2)+1],[1 1],'Color','k','linewidth',2)
                            line([max(T_interp_2)+1-0.3 max(T_interp_2)+1],[1.05 1],'Color','k','linewidth',2)
                            line([max(T_interp_2)+1-0.3 max(T_interp_2)+1],[0.95 1],'Color','k','linewidth',2)
                            
                            
                            
                            hold on
                            plot(T_injection,1,'.b','markersize',50)
                            text(T_injection,1.1,'Essai d''infiltration')
                            plot(T_interp_2(time),1,'ok','markersize',10,'MarkerEdgeColor','w' ,'MarkerFaceColor',[0,0,0])
                            xlim([min(T_interp_2) max(T_interp_2)+1])
                            
                            
                            grid minor
                            ax = gca;
                            ax.XTick=[pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps))];
                            ax.XTickLabel =[datestr(pas_de_temps*unique(round(T_interp_2(:,1)/pas_de_temps)),format)];
                            
                            set(gca,'ytick',[])
                            
                            
                        end
                    end
                end
            end
        end
    end
    
end


