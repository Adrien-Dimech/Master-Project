%% ----------------- 3D-geoelectrical-database-to-RES2D\3DINV -------------------------
%
% Adrien Dimech - Master Project - 21/04/2018
%
% -------------------------------------------------------------------------
% Matlab codes to prepare - process - visualize and interpret 3D time-lapse
% geolelectrical monitoring of a waste rock pile.
% -------------------------------------------------------------------------
%
% This Matlab code was designed to process 3D geoelectrical database of the
% experimental waste rock pile to RES2DINV and RES3DINV inversion software.
% Both surface and borehole electrodes are used for meausurements with
% standard and optimized protocols. 2D and 3D txt files are created for 2D
% and 3D inversion with user-selected protocols.
%
% Feel free to visit : https://www.researchgate.net/profile/Adrien_Dimech
% for more information about my research or contact me for more information
% and data files : adrien.dimech@gmail.com
%
% %% CODE DE MISE EN FORME DES DONNEES POUR RES2DINV
% -------------------------------------------------------------------------
%
%
%                           Suivi du code
% -------------------------------------------------------------------------
% Creation          |       07/11/2016        |     Adrien Dimech
% -------------------------------------------------------------------------
% Modification      |       10/11/2016        |     Adrien Dimech
% -------------------------------------------------------------------------
% Modification      |       23/11/2016        |     Adrien Dimech
% -------------------------------------------------------------------------

%% 0) Chargement des donnees
% Creation le 07/11/2016
for o=1
    close all
    clear all
    indfig = 0;
    TOffset = 1.1672;
    
    % Electrodes
    %ELEC = xlsread('SYNTHESE.xlsx',3);
    load('ELEC.mat')
    
    % Informations essais
    %INFO = xlsread('SYNTHESE.xlsx',2);
    load('INFO.mat')
    
    % Ensembles d'electrodes
    %ENS = xlsread('SYNTHESE.xlsx',4);
    load('ENS.mat')
    
    % Protocoles
    load('PRO_FINAUX.mat');
    
    % Donnees
    NbEssais = length(INFO(:,1));
    
    % for i=1:NbEssais
    %     RAW_DATA{i}=xlsread('RAW_DATA.xlsx',INFO(i,1));
    % end
    %load('RAW_DATA.mat');
    load('DATA1.mat');
end

%% 1) Choix des donnees
% Creation le 07/11/2016
% Modification le 10/11/2016
% Modification le 23/11/2016
for o=1
    % Type de donnees (Resistance ou Resistivite)
    TypeDonnee = menu('Quel type de donnees ?','App Resistivity','Resistance');
    TypeD = [0 , 1];
    TypeDonnee=TypeD(1,TypeDonnee);
    
    % Dimension de l'imagerie (2D ou 3D)
    Dimension = menu('Quelle dimension pour l"imagerie ?','2D','3D');
    
    % Protocoles et configurations
    prompt = {sprintf('Quels protocoles ? \n \n Pour selection multiple utilisez des espaces \n \n (1=Wenner-Schlum, 2=dip-dip, 3=dip-dip equa, 4=cross diag dip-dip, \n 5=multi grad, 6=(B)diag dip-dip, 7=(B)dip-dip equa, 0=tous) \n')};
    dlg_title = 'TypeProtocole';
    num_lines = 1;
    defaultans = {'1'};
    TypeProtocole = inputdlg(prompt,dlg_title,num_lines,defaultans);
    TypeProtocole = str2num(TypeProtocole{:});
    
    if TypeProtocole==0
        for i=1:7
            TypeProtocole(1,i)=i;
        end
    end
    
    Name = {'WS','DD','DDE','CDDD','MG','Bor_CDDD','Bor_DDE'};
    
    if Dimension ==1
        % Coupe désirée
        Yselect = menu('Quelle section de la halde ?','Y = 2 m','Y = 4 m', 'Y = 6 m','Y = 8 m' );
        Yselection=[2 4 6 8];
        Yselect = Yselection(1,Yselect);
    end
    
    % Choix des essais
    MESA4 = [12;18;33;54;57;59;61;63;65];
    MESA3_6 = [25;53;55;58;60;62;64;83;103];
    MESAHAUT = [25;33];
    MESABAS = [28;30];
    MESA3 = [12;14;15;17;18];
    MESA3 = [53;55;58;60;62;64];
    MESB3=[40 ; 40];
    MESA1_2=[28;30];
    MESA = [25;33;28;30;46;52];
    MESA_B = [25;33;28;30;34];
    MESA_B = [25;33;28;30;34;38;40;42];
    MESAHAUT2 = [53;54];
    TIMELAPSE = 25
    
    MESA = [25;33;28;30;46;52];
    MESAH = [25;33;52];
    MESAB = [28;30;46];
    Ensemble = MESAB;
end

%% 2) Selection des donnees pertinentes
% Creation le 07/11/2016
for o=1
    % Selection des donnees à partir de DATA1
    for i=1:length(Ensemble(:,1))
        Ensemble2(i,1) = find(INFO(:,1)== Ensemble(i,1));
        DATA2{i}=DATA1{Ensemble2(i,1)};
        if Dimension ==1
            DATA3{i}=DATA2{i}(find(DATA2{i}(:,15)==Yselect),:);
        else
            DATA3{i}=DATA2{i};
        end
        colENS = floor(INFO(Ensemble2(i,1),5));
        for m=1:length(TypeProtocole(1,:))
            Protocole{i,m}=PRO_FINAUX(find(PRO_FINAUX(:,2)==TypeProtocole(1,m)),:);
            Protocole2{i,m}=Protocole{i,m};
            for j=1:length(Protocole{i,m}(:,1))
                for k=1:4
                    Protocole2{i,m}(j,k+2)=ENS(Protocole{i,m}(j,k+2)+1,colENS);
                end
            end
        end
    end
    
    % Selection des informations des protocoles selectionnes
    for i=1:length(Ensemble(:,1))
        for m=1:length(TypeProtocole(1,:))
            for j=1:length(Protocole2{i,m}(:,1))
                rowDATA3=find(DATA3{i}(:,1)==Protocole2{i,m}(j,3)&DATA3{i}(:,2)==Protocole2{i,m}(j,4)&DATA3{i}(:,3)==Protocole2{i,m}(j,5)&DATA3{i}(:,4)==Protocole2{i,m}(j,6));
                if isempty(rowDATA3)==0
                    Protocole2{i,m}(j,9:19)=DATA3{i}(rowDATA3,5:15);
                end
            end
            if length(Protocole2{i,m}(1,:))<9
                Protocole2{i,m}=[];
            else
                Protocole2{i,m}(find(Protocole2{i,m}(:,9)==0),:)=[];
            end
        end
    end
end

%% 3) Borehole = Ecriture des fichiers .txt pour RES2DINV
% Creation le 10/11/2016
% Modification le 11/11/2016 (concaténation données pour 2 essais diff.)
% Modification le 11/11/2016 (ajout des donnees d'erreurs des mesures)
% Modification le 21/11/2016 (suppression du mode "surface")
for o=1
    if Dimension ==1                    % CAS 2D
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Concaténation des données de protocole
        if length(TypeProtocole(1,:))>1
            for j=1:length(Ensemble(:,1))
                Protocole3{j,1}=Protocole2{j,1};
                for i=2:length(TypeProtocole(1,:))
                    Protocole3{j,1}=[Protocole3{j,1}(:,:) ; Protocole2{j,i}(:,:)];
                end
            end
        else
            Protocole3=Protocole2;
        end
        
        % Prise en compte des erreurs de mesures (variance %)
        Erreur = menu(['Prendre en compte les variances de mesure ?'],'OUI','NON');
        
        % Identification des donnees pertinentes
        for i=1:length(Ensemble(:,1))
            for j=1:length(Protocole3{i,1}(:,1))
                DATA4{i}(j,1)=4;
                for k=1:4
                    E=Protocole3{i,1}(j,k+2);
                    DATA4{i}(j,1+2*(k-1)+1)=ELEC(E,5);
                    if E>96
                        DATA4{i}(j,1+2*k)=1;
                    else
                        DATA4{i}(j,1+2*k)=7;
                    end
                end
                % Écriture des données
                if TypeDonnee==0        % résistivité app
                    DATA4{i}(j,10)=Protocole3{i,1}(j,17);
                elseif TypeDonnee==1    % résistance
                    DATA4{i}(j,10)=Protocole3{i,1}(j,12);
                end
                % Écriture des erreurs
                if Erreur ==1
                    if TypeDonnee==0        % résistivité app
                        DATA4{i}(j,11)=Protocole3{i,1}(j,12)*Protocole3{i,1}(j,13)/100;
                    elseif TypeDonnee==1    % résistance
                        DATA4{i}(j,11)=Protocole3{i,1}(j,12)*Protocole3{i,1}(j,13)*Protocole3{i,1}(j,8)/100;
                    end
                end
            end
        end
        
        
        % Concatenation de plusieurs essais differents
        if length(Ensemble(:,1))>1
            Concat = menu(['Concatener les donnees des ' num2str(length(Ensemble(:,1))),' essai(s) ?'],'OUI','NON')
            if Concat == 1
                DATA5{1}=DATA4{1};
                for i=2:length(Ensemble(:,1))
                    DATA5{1}=[DATA5{1}(:,:);DATA4{i}(:,:)];
                end
                clear DATA4
                DATA4=DATA5;
                clear DATA5
            end
        else
            Concat =2;
        end
        
        % Raffinage de l'inversion sur RES2DINV
        RaffX = menu('Quelle largeur des mailles RES2DINV ?','0.5 m','1 m','1,5 m','2 m');
        RaffinageX=[0.5,1,1.5,2];
        RaffX=RaffinageX(1,RaffX);
        
        RaffZ = menu('Quelle hauteur des mailles RES2DINV ?','0.05 m','0.1 m','0.5 m');
        RaffinageZ=[0.05,0.1,0.5];
        RaffZ=RaffinageZ(1,RaffZ);
        
        % Mise en forme du .txt pour RES2DINV
        % Nom des protocoles
        Name2=Name{1,TypeProtocole(1,1)};
        if length(TypeProtocole(1,:))>1
            for i=2:length(TypeProtocole(1,:))
                Name2=[Name2, '-', Name{1,TypeProtocole(1,i)}];
            end
        end
        
        if Concat == 2  % pas de concaténation
            for i=1:length(Ensemble(:,1))
                Nom_Inversion = ['Borehole : E',num2str(Ensemble(i,1)), ' ; ', datestr(INFO(Ensemble2(i,1),4)-1), ' ; ', Name2, ' ; Y = ',num2str(Yselect),' m ; (', datestr(now),')'];
                Nom_Fichier = ['Borehole_E',num2str(Ensemble(i,1)), '_', Name2, '_Y=',num2str(Yselect),'m'];
                
                % En-tete du fichier
                fileID = fopen([Nom_Fichier,'.txt'],'w');
                % Title
                fprintf(fileID,'%6s \r\n',Nom_Inversion);
                % Smallest electrode spacing
                fprintf(fileID,'%6.3f \r\n',min([RaffX,RaffZ]));
                Xelec=unique([DATA4{1,i}(:,2);DATA4{1,i}(:,4);DATA4{1,i}(:,6);DATA4{1,i}(:,8)]);
                % Array number
                % 12 si donnees sous forme de app res
                % 13 si donnees sous forme de R
                if TypeDonnee == 0
                    fprintf(fileID,'%6.0f \r\n',12);
                elseif TypeDonnee == 1
                    fprintf(fileID,'%6.0f \r\n',13);
                end
                
                % Number of data points
                A=[length(DATA4{1,i}(:,1));length(Xelec(:,1));0];
                fprintf(fileID,'%6.0f \r\n',A);
                
                % Surface electrodes
                fprintf(fileID,'%6s \r\n','Surface Electrodes');
                NbElecX = (max(Xelec)-min(Xelec)+4)/RaffX+1;
                fprintf(fileID,'%6.0f \r\n',NbElecX);
                for j=1:NbElecX
                    fprintf(fileID,'%6.3f %6.3f  \r\n',[min(Xelec)-2+(j-1)*RaffX,0]);
                end
                
                % Boreholes
                fprintf(fileID,'%6s \r\n','Number of boreholes');
                fprintf(fileID,'%6.0f \r\n',length(Xelec(:,1)));
                NbElecZ = 7/RaffZ;
                for j=1:length(Xelec(:,1))
                    fprintf(fileID,'%6s \r\n',['Borehole ',num2str(j),' Electrodes']);
                    fprintf(fileID,'%6.0f \r\n',NbElecZ);
                    for k=1:NbElecZ
                        fprintf(fileID,'%6.3f %6.3f  \r\n',[Xelec(j,1),k*RaffZ]);
                    end
                end
                
                % Error Data
                if Erreur ==1
                    fprintf(fileID,'%6s \r\n','Error estimate for data present');
                    fprintf(fileID,'%6s \r\n','Type of error estimate (0=same unit as data)');
                    fprintf(fileID,'%6s \r\n','0');
                end
                
                % Data
                fprintf(fileID,'%6s \r\n','Measured Data');
                for j=1:length(DATA4{1,i}(:,1))
                    fprintf(fileID,'%6.0f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.8f %6.8f \r\n',DATA4{i}(j,:));
                end
                A=[0;0;0;0;0];
                fprintf(fileID,'%6.0f \r\n',A);
                fclose(fileID);
            end
        else        % Concaténation
            Nom_Essai_Concat = ['E',num2str(Ensemble(1,1))];
            Nom_Essai_Concat2 = ['E',num2str(Ensemble(1,1))];
            for i=2:length(Ensemble(:,1))
                Nom_Essai_Concat = [Nom_Essai_Concat,' ; E',num2str(Ensemble(i,1))];
                Nom_Essai_Concat2 = [Nom_Essai_Concat2,'_E',num2str(Ensemble(i,1))];
            end
            
            Nom_Inversion = ['Borehole : ',Nom_Essai_Concat, ' ; ', datestr(INFO(Ensemble2(1,1),4)-1), ' ; ', Name2, ' ; Y = ',num2str(Yselect),' m ; (', datestr(now),')'];
            Nom_Fichier = ['Borehole_',Nom_Essai_Concat2, '_', Name2, '_Y=',num2str(Yselect),'m'];
            
            % En-tete du fichier
            i=1;
            fileID = fopen([Nom_Fichier,'.txt'],'w');
            fprintf(fileID,'%6s \r\n',Nom_Inversion);
            fprintf(fileID,'%6.3f \r\n',min([RaffX,RaffZ]));
            Xelec=unique([DATA4{1,1}(:,2);DATA4{1,1}(:,4);DATA4{1,1}(:,6);DATA4{1,1}(:,8)]);
            
            % Array number
            % 12 si donnees sous forme de app res
            % 13 si donnees sous forme de R
            if TypeDonnee == 0
                fprintf(fileID,'%6.0f \r\n',12);
            elseif TypeDonnee == 1
                fprintf(fileID,'%6.0f \r\n',13);
            end
            
            
            A=[length(DATA4{1,1}(:,1));length(Xelec(:,1));0];
            fprintf(fileID,'%6.0f \r\n',A);
            
            % Surface electrodes
            fprintf(fileID,'%6s \r\n','Surface Electrodes');
            NbElecX = (max(Xelec)-min(Xelec)+4)/RaffX+1;
            fprintf(fileID,'%6.0f \r\n',NbElecX);
            for j=1:NbElecX
                fprintf(fileID,'%6.3f %6.3f  \r\n',[min(Xelec)-2+(j-1)*RaffX,0]);
            end
            
            % Boreholes
            fprintf(fileID,'%6s \r\n','Number of boreholes');
            fprintf(fileID,'%6.0f \r\n',length(Xelec(:,1)));
            NbElecZ = 7/RaffZ;
            for j=1:length(Xelec(:,1))
                fprintf(fileID,'%6s \r\n',['Borehole ',num2str(j),' Electrodes']);
                fprintf(fileID,'%6.0f \r\n',NbElecZ);
                for k=1:NbElecZ
                    fprintf(fileID,'%6.3f %6.3f  \r\n',[Xelec(j,1),k*RaffZ]);
                end
            end
            
            % Error Data
            if Erreur ==1
                fprintf(fileID,'%6s \r\n','Error estimate for data present');
                fprintf(fileID,'%6s \r\n','Type of error estimate (0=same unit as data)');
                fprintf(fileID,'%6s \r\n','0');
            end
            
            % Data
            fprintf(fileID,'%6s \r\n','Measured Data');
            for j=1:length(DATA4{1,i}(:,1))
                fprintf(fileID,'%6.0f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.8f %6.8f \r\n',DATA4{i}(j,:));
            end
            A=[0;0;0;0;0];
            fprintf(fileID,'%6.0f \r\n',A);
            fclose(fileID);
        end
    else                    % CAS 3D
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Concaténation des données de protocole
        if length(TypeProtocole(1,:))>1
            for j=1:length(Ensemble(:,1))
                Protocole3{j,1}=Protocole2{j,1};
                for i=2:length(TypeProtocole(1,:))
                    Protocole3{j,1}=[Protocole3{j,1}(:,:) ; Protocole2{j,i}(:,:)];
                end
            end
        else
            Protocole3=Protocole2;
        end
        
        % Prise en compte des erreurs de mesures (variance %)
        Erreur = menu(['Prendre en compte les variances de mesure ?'],'OUI','NON');
        
        % Identification des donnees pertinentes
        for i=1:length(Ensemble(:,1))
            for j=1:length(Protocole3{i,1}(:,1))
                DATA4{i}(j,1)=4;
                for k=1:4
                    E=Protocole3{i,1}(j,k+2);
                    DATA4{i}(j,1+3*(k-1)+1)=ELEC(E,5);
                    DATA4{i}(j,1+3*(k-1)+2)=ELEC(E,6);
                    if E>96
                        DATA4{i}(j,1+3*k)=0;
                    else
                        DATA4{i}(j,1+3*k)=6;
                    end
                end
                % Écriture des données
                if TypeDonnee==0        % résistivité app
                    DATA4{i}(j,14)=Protocole3{i,1}(j,17);
                elseif TypeDonnee==1    % résistance
                    DATA4{i}(j,14)=Protocole3{i,1}(j,12);
                end
                % Écriture des erreurs
                if Erreur ==1
                    if TypeDonnee==0        % résistivité app
                        DATA4{i}(j,15)=Protocole3{i,1}(j,12)*Protocole3{i,1}(j,13)/100;
                    elseif TypeDonnee==1    % résistance
                        DATA4{i}(j,15)=Protocole3{i,1}(j,12)*Protocole3{i,1}(j,13)*Protocole3{i,1}(j,8)/100;
                    end
                end
            end
        end
        
        
        % Concatenation de plusieurs essais differents
        if length(Ensemble(:,1))>1
            Concat = menu(['Concatener les donnees des ' num2str(length(Ensemble(:,1))),' essai(s) ?'],'OUI','NON')
            if Concat == 1
                DATA5{1}=DATA4{1};
                for i=2:length(Ensemble(:,1))
                    DATA5{1}=[DATA5{1}(:,:);DATA4{i}(:,:)];
                end
                clear DATA4
                DATA4=DATA5;
                clear DATA5
            end
        else
            Concat =2;
        end
        
        RaffZ = menu('Quelle hauteur des mailles RES3DINV ?','0.5 m','1 m');
        RaffinageZ=[0.5,1];
        RaffZ=RaffinageZ(1,RaffZ);
        RaffX=RaffZ;
        RaffY=RaffZ;
        
        % Mise en forme du .txt pour RES3DINV
        % Nom des protocoles
        Name2=Name{1,TypeProtocole(1,1)};
        if length(TypeProtocole(1,:))>1
            for i=2:length(TypeProtocole(1,:))
                Name2=[Name2, '-', Name{1,TypeProtocole(1,i)}];
            end
        end
        %Name2 = 'tout';
        
        if Concat == 2  % pas de concaténation
            for i=1:length(Ensemble(:,1))
                Nom_Inversion = ['Borehole : E',num2str(Ensemble(i,1)), ' ; ', datestr(INFO(Ensemble2(i,1),4)-1), ' ; ', Name2, ' ; Y = ',num2str(Yselect),' m ; (', datestr(now),')'];
                Nom_Fichier = ['Borehole_E',num2str(Ensemble(i,1)), '_', Name2, '_Y=',num2str(Yselect),'m'];
                
                % En-tete du fichier
                fileID = fopen([Nom_Fichier,'.dat'],'w');
                % Title
                fprintf(fileID,'%6s \r\n',Nom_Inversion);
                % Smallest electrode spacing
                fprintf(fileID,'%6.3f \r\n',min([RaffX,RaffZ]));
                Xelec=unique([DATA4{1,i}(:,2);DATA4{1,i}(:,4);DATA4{1,i}(:,6);DATA4{1,i}(:,8)]);
                % Array number
                % 12 si donnees sous forme de app res
                % 13 si donnees sous forme de R
                if TypeDonnee == 0
                    fprintf(fileID,'%6.0f \r\n',12);
                elseif TypeDonnee == 1
                    fprintf(fileID,'%6.0f \r\n',13);
                end
                
                % Number of data points
                A=[length(DATA4{1,i}(:,1));length(Xelec(:,1));0];
                fprintf(fileID,'%6.0f \r\n',A);
                
                % Surface electrodes
                fprintf(fileID,'%6s \r\n','Surface Electrodes');
                NbElecX = (max(Xelec)-min(Xelec)+4)/RaffX+1;
                fprintf(fileID,'%6.0f \r\n',NbElecX);
                for j=1:NbElecX
                    fprintf(fileID,'%6.3f %6.3f  \r\n',[min(Xelec)-2+(j-1)*RaffX,0]);
                end
                
                % Boreholes
                fprintf(fileID,'%6s \r\n','Number of boreholes');
                fprintf(fileID,'%6.0f \r\n',length(Xelec(:,1)));
                NbElecZ = 7/RaffZ;
                for j=1:length(Xelec(:,1))
                    fprintf(fileID,'%6s \r\n',['Borehole ',num2str(j),' Electrodes']);
                    fprintf(fileID,'%6.0f \r\n',NbElecZ);
                    for k=1:NbElecZ
                        fprintf(fileID,'%6.3f %6.3f  \r\n',[Xelec(j,1),k*RaffZ]);
                    end
                end
                
                % Error Data
                if Erreur ==1
                    fprintf(fileID,'%6s \r\n','Error estimate for data present');
                    fprintf(fileID,'%6s \r\n','Type of error estimate (0=same unit as data)');
                    fprintf(fileID,'%6s \r\n','0');
                end
                
                % Data
                fprintf(fileID,'%6s \r\n','Measured Data');
                for j=1:length(DATA4{1,i}(:,1))
                    fprintf(fileID,'%6.0f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.8f %6.8f \r\n',DATA4{i}(j,:));
                end
                A=[0;0;0;0;0];
                fprintf(fileID,'%6.0f \r\n',A);
                fclose(fileID);
            end
        else        % Concaténation
            Nom_Essai_Concat = ['E',num2str(Ensemble(1,1))];
            Nom_Essai_Concat2 = ['E',num2str(Ensemble(1,1))];
            for i=2:length(Ensemble(:,1))
                Nom_Essai_Concat = [Nom_Essai_Concat,' ; E',num2str(Ensemble(i,1))];
                Nom_Essai_Concat2 = [Nom_Essai_Concat2,'_E',num2str(Ensemble(i,1))];
            end
            
            Nom_Inversion = ['Borehole3D : ',Nom_Essai_Concat, ' ; ', datestr(INFO(Ensemble2(1,1),4)-1), ' ; ', Name2, ' (', datestr(now),')'];
            Nom_Fichier = ['Borehole3D_',Nom_Essai_Concat2, '_', Name2];
            
            % En-tete du fichier
            i=1;
            fileID = fopen([Nom_Fichier,'.dat'],'w');
            fprintf(fileID,'%6s \r\n',Nom_Inversion);
            
            
            % X and Y grid size
            Xelec=unique([DATA4{1,1}(:,2);DATA4{1,1}(:,5);DATA4{1,1}(:,8);DATA4{1,1}(:,11)]);
            Yelec=unique([DATA4{1,1}(:,3);DATA4{1,1}(:,6);DATA4{1,1}(:,9);DATA4{1,1}(:,12)]);
            
            %         Xmin = min(Xelec)-2;
            %         Xmax = max(Xelec)+2;
            %         Ymin = min(Yelec)-2;
            %         Ymax = max(Yelec)+2;
            
            Xmin = 0;
            Xmax = 60;
            Ymin = 0;
            Ymax = 10;
            
            XGridSize = (Xmax-Xmin)/RaffX+1 ;
            YGridSize = (Ymax-Ymin)/RaffY+1 ;
            
            fprintf(fileID,'%6.0f \r\n',[XGridSize,YGridSize]);
            
            fprintf(fileID,'%6.3f \r\n',[RaffX,RaffY]);
            
            
            % Array number
            % 12 si donnees sous forme de app res
            % 13 si donnees sous forme de R
            if TypeDonnee == 0
                fprintf(fileID,'%6.0f \r\n',12);
            elseif TypeDonnee == 1
                fprintf(fileID,'%6.0f \r\n',13);
            end
            
            % Borehole 0 0
            NbElecZ = 7/RaffZ;
            
            % Number of boreholes
            % Modif 24/11/2016 - ajout d'un borehole a X=0 Y=0
            NbBoreholes = length(Xelec(:,1))*length(Yelec(:,1))+4;
            fprintf(fileID,'%6s \r\n','Number of boreholes');
            fprintf(fileID,'%6.0f \r\n',NbBoreholes);
            
            fprintf(fileID,'%6s \r\n',['Borehole a1']);
            fprintf(fileID,'%6.0f \r\n',NbElecZ);
            for k=1:NbElecZ
                fprintf(fileID,'%6.3f %6.3f %6.3f \r\n',[0,0,k*RaffZ]);
            end
            
            fprintf(fileID,'%6s \r\n',['Borehole a2']);
            fprintf(fileID,'%6.0f \r\n',NbElecZ);
            for k=1:NbElecZ
                fprintf(fileID,'%6.3f %6.3f %6.3f \r\n',[60,0,k*RaffZ]);
            end
            
            fprintf(fileID,'%6s \r\n',['Borehole a3']);
            fprintf(fileID,'%6.0f \r\n',NbElecZ);
            for k=1:NbElecZ
                fprintf(fileID,'%6.3f %6.3f %6.3f \r\n',[0,10,k*RaffZ]);
            end
            
            fprintf(fileID,'%6s \r\n',['Borehole a4']);
            fprintf(fileID,'%6.0f \r\n',NbElecZ);
            for k=1:NbElecZ
                fprintf(fileID,'%6.3f %6.3f %6.3f \r\n',[60,10,k*RaffZ]);
            end
            
            for i=1:length(Xelec(:,1))
                for j=1:length(Yelec(:,1))
                    fprintf(fileID,'%6s \r\n',['Borehole ',num2str((i-1)*4+j),' Electrodes ']);
                    fprintf(fileID,'%6.0f \r\n',NbElecZ);
                    
                    for k=1:NbElecZ
                        fprintf(fileID,'%6.3f %6.3f %6.3f \r\n',[Xelec(i,1),Yelec(j,1),k*RaffZ]);
                    end
                end
            end
            
            %         % Error Data
            %         if Erreur ==1
            %             fprintf(fileID,'%6s \r\n','Error estimate for data present');
            %             fprintf(fileID,'%6s \r\n','Type of error estimate (0=same unit as data)');
            %             fprintf(fileID,'%6s \r\n','0');
            %         end
            
            % Data
            fprintf(fileID,'%6s \r\n','Measured Data');
            fprintf(fileID,'%6.0f \r\n',length(DATA4{1,1}(:,1))+1);
            
            fprintf(fileID,'%6.0f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.8f \r\n',[4 0 0 1 2 8 1 2 4 1 2 6 1 60]);
            
            for j=1:length(DATA4{1,1}(:,1))
                % fprintf(fileID,'%6.0f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.8f %6.8f \r\n',DATA4{1}(j,:));
                fprintf(fileID,'%6.0f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.8f \r\n',DATA4{1}(j,1:14));
            end
            A=[0;0;0;0;0];
            fprintf(fileID,'%6.0f \r\n',A);
            fclose(fileID);
        end
    end
end
