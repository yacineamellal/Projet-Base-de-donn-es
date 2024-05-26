-- ********* B- Création des TableSpaces et utilisateur  :***********


DROP USER SQL3 CASCADE;


-- 2-Création des tablespaces

CREATE TABLESPACE SQL3_TBS
DATAFILE 'c:\mytbs.dat'
SIZE 100M
AUTOEXTEND ON
NEXT 10M
MAXSIZE UNLIMITED;

CREATE TEMPORARY TABLESPACE SQL3_TempTBS
TEMPFILE 'c:\mytemptbs.dat'
SIZE 50M
AUTOEXTEND ON
NEXT 5M
MAXSIZE UNLIMITED;

-- 3-Création de l'utilisateur et attribution des tablespaces

CREATE USER SQL3 IDENTIFIED BY psw
DEFAULT TABLESPACE SQL3_TBS
TEMPORARY TABLESPACE SQL3_TempTBS
QUOTA UNLIMITED ON SQL3_TBS;


-- 4-Attribution de tous les privilèges à l'utilisateur SQL3

GRANT ALL PRIVILEGES TO SQL3;

connect SQL3/psw;


-- ********* C- Langage de définition de données :**********

-- 5-

-- définition des types incomplets: vue que les types s'utilisent de manière biderectionnelle, on idique au SGBD que le type existe sans rentre dans le détail pour qu'on puissse définir les relations.
create type tclient;
/

create type tvehicule;
/

create type tmodele;
/

create type tmarque;
/

create type tintervention;
/

create type tintervenant;
/

create type temployer;
/

-- cette instruction permet de définir une table imbriquée de référence des objets de type tvehicule
create type t_set_ref_vehicule as table of ref tvehicule;
/

-- cette instruction permet de définir une table imbriquée de référence des objets de type tmodele
create type t_set_ref_modele as table of ref tmodele;
/

-- cette instruction permet de définir une table imbriquée de référence des objets de type tintervention
create type t_set_ref_intervention as table of ref tintervention;
/

-- cette instruction permet de définir une table imbriquée de référence des objets de type tintervenant
create type t_set_ref_intervenant as table of ref tintervenant;
/


-- création de type tclient
create or replace type tclient as object (NUMCLIENT INTEGER,
CIV varchar2(5),
PRENOMCLIENT varchar2(50),
NOMCLIENT varchar2(50),
DATENAISSANCE DATE, 
ADRESSE varchar2(100),
TELPROF varchar2(20),
TELPRIV varchar2(20),
FAX varchar2(20), 
client_vehicule t_set_ref_vehicule);
/

-- création de type tmarque
create or replace type tmarque as object (NUMMARQUE INTEGER, 
MARQUE varchar2(30),
PAYS varchar2(30),
MARQUE_MODELE t_set_ref_modele);
/

-- création de type tmodele
create or replace type tmodele as object (NUMMODELE INTEGER, 
NUMMARQUE ref tmarque,
MODELE varchar2(30),
modele_vehicule t_set_ref_vehicule);
/

-- création de type tvehicule
CREATE OR REPLACE TYPE tvehicule AS OBJECT (
   NUMVEHICULE INTEGER,
   NUMCLIENT REF tclient,
   NUMMODELE REF tmodele,
   NUMIMMAT INTEGER,
   ANNEE VARCHAR2(5),
   vehicule_intervention t_set_ref_intervention)
/

-- création de type tintervention
create or replace type tintervention as object (NUMINTERVENTION INTEGER,
NUMVEHICULE ref tvehicule,
TYPEINTERVENTION varchar2(50),
DATEDEBINTRV DATE,
DATEFININTRV DATE,
COUTINTERV REAL,
intervention_intervenant t_set_ref_intervenant);
/

-- création de type temployer
create or replace type temployer as object (NUMEMPLOYER INTEGER,
NOMEMP varchar(50),
PRENOMEMP varchar(50),
CATEGORIE varchar(50),
SALAIRE REAL,
employer_intervenant t_set_ref_intervenant);
/

-- création de type tintervenant
create or replace type tintervenant as object (NUMINTERVENTION ref tintervention, 
NUMEMPLOYE ref temployer, 
DATEDEBUT date, 
DATEFIN date);
/


-- 6-les méthodes :

-- 1er methode : Calculer pour chaque employé, le nombre des interventions effectuées.

-- signateur

alter type temployer add member function nb_interventions return integer cascade;

--body

-- Définition du corps de la méthode pour calculer le nombre d'interventions effectuées par un employé

CREATE OR REPLACE TYPE BODY temployer AS
 MEMBER FUNCTION nb_interventions RETURN INTEGER IS
 nombre_interventions INTEGER := 0;
 BEGIN
 nombre_interventions := self.employer_intervenant.COUNT;
 RETURN nombre_interventions;
 END;
END;
/


-- 2em methode : Calculer pour chaque marque, le nombre de modèles.

-- signateur

alter type tmarque add member function calcul_modeles return integer cascade;

--body

-- Définition du corps de la méthode pour calculer le nombre de modèles pour une marque

CREATE OR REPLACE TYPE BODY tmarque AS
 MEMBER FUNCTION calcul_modeles RETURN INTEGER IS
 nombre_modeles INTEGER := 0;
 BEGIN
 nombre_modeles := self.MARQUE_MODELE.COUNT;
 RETURN nombre_modeles;
 END;
END;
/


-- 3em methode : Calculer pour chaque modèle, le nombre de véhicules. 

-- signateur

alter type tmodele add member function calcul_vehicules return integer cascade;

--body

-- Définition du corps de la méthode pour calculer le nombre de véhicules pour un modèle

CREATE OR REPLACE TYPE BODY tmodele AS
 MEMBER FUNCTION calcul_vehicules RETURN INTEGER IS
 nombre_vehicules INTEGER := 0;
 BEGIN
 nombre_vehicules := self.modele_vehicule.COUNT;
 RETURN nombre_vehicules;
 END;
END;
/

-- 4em methode : Lister pour chaque client, ses véhicules.

-- signateur

alter type tclient add member function lister_vehicules RETURN t_set_ref_vehicule cascade;

--body

-- Définition du corps de la méthode pour lister les véhicules de chaque client

CREATE OR REPLACE TYPE BODY tclient AS
 MEMBER FUNCTION lister_vehicules RETURN t_set_ref_vehicule IS
 BEGIN
 RETURN self.client_vehicule;
 END;
END;
/


-- 5em methode : Calculer pour chaque marque, son chiffre d’affaire.

-- signateur

alter type tmarque add member function chiffre_affaire return NUMBER cascade;

--body

-- Définition du corps de la méthode pour calculer le chiffre d'affaires pour chaque marque

CREATE OR REPLACE TYPE BODY tmarque AS
  MEMBER FUNCTION chiffre_affaire RETURN NUMBER
  IS
    l_chiffre_affaires NUMBER := 0;
  BEGIN
    -- Parcourir tous les modèles de la marque
    FOR m IN (SELECT VALUE(mod) FROM TABLE(self.MARQUE_MODELE) mod)
    LOOP
      -- Parcourir tous les véhicules de chaque modèle
      FOR v IN (SELECT VALUE(veh) FROM TABLE(m.modele_vehicule) veh)
      LOOP
        -- Parcourir toutes les interventions de chaque véhicule
        FOR i IN (SELECT VALUE(inter) FROM TABLE(v.vehicule_intervention) inter)
        LOOP
          -- Ajouter le coût de l'intervention au chiffre d'affaires
          l_chiffre_affaires := l_chiffre_affaires + i.COUTINTERV;
        END LOOP;
      END LOOP;
    END LOOP;
    RETURN l_chiffre_affaires;
  END chiffre_affaire;
END;
/



-- 7-creation des tables :

create table client OF tclient (
    NUMCLIENT PRIMARY KEY,
    CONSTRAINT civ_check CHECK (CIV IN ('M', 'Mle', 'Mme'))
)
nested table client_vehicule store as table_client_vehicule;


create table marque of tmarque (PRIMARY KEY(NUMMARQUE))
nested table MARQUE_MODELE store as table_MARQUE_MODELE;


create table modele of tmodele (
    NUMMODELE PRIMARY KEY,
    CONSTRAINT fk_marque FOREIGN KEY (NUMMARQUE) REFERENCES marque
)
nested table modele_vehicule store as table_modele_vehicule;


create table vehicule of tvehicule (
    NUMVEHICULE PRIMARY KEY,
    CONSTRAINT fk_client FOREIGN KEY (NUMCLIENT) REFERENCES client,
    CONSTRAINT fk_modele FOREIGN KEY (NUMMODELE) REFERENCES modele
)
nested table vehicule_intervention store as table_vehicule_intervention;


create table intervention of tintervention (
    NUMINTERVENTION PRIMARY KEY,
    CONSTRAINT fk_vehicule FOREIGN KEY (NUMVEHICULE) REFERENCES vehicule
)
nested table intervention_intervenant store as table_intervention_intervenant;


create table employer OF temployer (
    NUMEMPLOYER PRIMARY KEY,
    CONSTRAINT categorie_check CHECK (CATEGORIE in ('Mécanicien','Assistant'))
)
nested table employer_intervenant store as table_employer_intervenant;


create table intervenant of tintervenant (
    CONSTRAINT fk_intervention FOREIGN KEY (NUMINTERVENTION) REFERENCES intervention,
    CONSTRAINT fk_employer FOREIGN KEY (NUMEMPLOYE) REFERENCES employer
);


-- ********* D- Langage de manipulation de données :**********

-- 8-

-- Insérer les données dans la table client

INSERT INTO client VALUES (1, 'Mme', 'Cherifa', 'MAHBOUBA', TO_DATE('08/08/1957', 'DD/MM/YYYY'), 'CITE 1013 LOGTS BT 61 Alger', '0561381813', '0562458714',NULL,t_set_ref_vehicule());

INSERT INTO client VALUES  (2, 'Mme', 'Lamia', 'TAHMI', TO_DATE('31/12/1955', 'DD/MM/YYYY'), 'CITE BACHEDJARAH BATIMENT 38 -Bach Djerrah-Alger', '0562467849', '0561392487',NULL,t_set_ref_vehicule());

INSERT INTO client VALUES  (3, 'Mle', 'Ghania', 'DIAF', TO_DATE('31/12/1955', 'DD/MM/YYYY'), '43, RUE ABDERRAHMANE SBAA BELLE VUE-EL HARRACH-ALGER', '0523894562', '0619430945','0562784254',t_set_ref_vehicule());

INSERT INTO client VALUES  (4, 'Mle', 'Chahinaz', 'MELEK', TO_DATE('27/06/1955', 'DD/MM/YYYY'), 'HLM AISSAT IDIR CAGE 9 3 EME ETAGE-EL HARRACH ALGER', '0634613493', '0562529463',NULL,t_set_ref_vehicule());

INSERT INTO client VALUES  (5, 'Mme', 'Noura', 'TECHTACHE', TO_DATE('22/03/1949', 'DD/MM/YYYY'), '16, ROUTE EL DJAMILA-AIN BENIAN-ALGER', '0562757834', '0562757843','0562757843',t_set_ref_vehicule());

INSERT INTO client VALUES  (6, 'Mme', 'Widad', 'TOUATI', TO_DATE('14/08/1965', 'DD/MM/YYYY'), '14 RUE DES FRERES AOUDIA-EL MOURADIA ALGER', '0561243967', '0561401836',NULL,t_set_ref_vehicule());

INSERT INTO client VALUES  (7, 'Mle', 'Faiza', 'ABLOUL', TO_DATE('28/10/1967', 'DD/MM/YYYY'), 'CITE DIPLOMATIQUE BT BLEU 14B N 3 DERGANA-ALGER', '0562935427', '0561486203',NULL,t_set_ref_vehicule());

INSERT INTO client VALUES (8, 'Mme', 'Assia', 'HORRA', TO_DATE('08/12/1963', 'DD/MM/YYYY'), '32 RUE AHMED OUAKED-DELY BRAHIM-ALGER', '0561038500', '0562466733','0562466733',t_set_ref_vehicule());

INSERT INTO client VALUES (9, 'Mle', 'Souad', 'MESBAH', TO_DATE('30/08/1972', 'DD/MM/YYYY'), 'RESIDENCE CHABANI-HYDRA-ALGER', '0561024358', NULL,NULL,t_set_ref_vehicule());

INSERT INTO client VALUES (10, 'Mme', 'Houda', 'GROUDA', TO_DATE('20/02/1950', 'DD/MM/YYYY'), 'EPSP THNIET ELABED BATNA', '0562939495', '0561218456',NULL,t_set_ref_vehicule());

INSERT INTO client VALUES (11, 'Mle', 'Saida', 'FENNICHE', NULL, 'CITE DE L INDEPENDANCE LARBAA BLIDA', '0645983165', '0562014784',NULL,t_set_ref_vehicule());

INSERT INTO client VALUES (12, 'Mme', 'Samia', 'OUALI', TO_DATE('17/11/1966', 'DD/MM/YYYY'), 'CITE 200 LOGEMENTS BT1 N1-JIJEL', '0561374812', '0561277013',NULL,t_set_ref_vehicule());

INSERT INTO client VALUES (13, 'Mme', 'Fatiha', 'HADDAD', TO_DATE('20/09/1980', 'DD/MM/YYYY'), 'RUE BOUFADA LAKHDARAT-AIN OULMANE-SETIF', '0647092453', '0562442700',NULL,t_set_ref_vehicule());

INSERT INTO client VALUES (14, 'M', 'Djamel', 'MATI', NULL, 'DRAA KEBILA HAMMAM GUERGOUR SETIF', '0561033663', '0561484259',NULL,t_set_ref_vehicule());

INSERT INTO client VALUES (15, 'M', 'Mohamed', 'GHRAIR', TO_DATE('24/06/1950', 'DD/MM/YYYY'), 'CITE JEANNE D ARC ECRAN B5-GAMBETTA – ORAN', '0561390288',NULL, '0562375849',t_set_ref_vehicule());

INSERT INTO client VALUES (16, 'M', 'Ali', 'LAAOUAR', NULL, 'CITE 1ER MAI EX 137 LOGEMENTS-ADRAR', '0639939410', '0561255412',NULL,t_set_ref_vehicule());
 
INSERT INTO client VALUES (17, 'M', 'Messoud', 'AOUIZ', TO_DATE('24/11/1958', 'DD/MM/YYYY'), 'RUE SAIDANI ABDESSLAM - AIN BESSEM-BOUIRA', '0561439256', '0561473625',NULL,t_set_ref_vehicule());

INSERT INTO client VALUES (18, 'M', 'Farid', 'AKIL', TO_DATE('06/05/1961', 'DD/MM/YYYY'), '3 RUE LARBI BEN M''HIDI-DRAA EL MIZAN-TIZI OUZOU', '0562349254', '0561294268',NULL,t_set_ref_vehicule());
 
INSERT INTO client VALUES (19, 'Mme', 'Dalila', 'MOUHTADI', NULL, '6 BD TRIPOLI ORAN', '0506271459', '0506294186',NULL,t_set_ref_vehicule());

INSERT INTO client VALUES (20, 'M', 'Younes', 'CHALAH', NULL, 'CITE DES 60 LOGTS BT D N 48-NACIRIA-BOUMERDES',NULL,'0561358279',NULL,t_set_ref_vehicule());

INSERT INTO client VALUES (21, 'M', 'Boubeker', 'BARKAT', TO_DATE('08/11/1935', 'DD/MM/YYYY'), 'CITE MENTOURI N 71 BT AB SMK Constantine', '0561824538', '0561326179',NULL,t_set_ref_vehicule());

INSERT INTO client VALUES (22, 'M', 'Seddik', 'HMIA', NULL, '25 RUE BEN YAHIYA-JIJEL', '0562379513',NULL, '0562493627',t_set_ref_vehicule());

INSERT INTO client VALUES (23, 'M', 'Lamine', 'MERABAT', TO_DATE('09/13/1965', 'MM/DD/YYYY'), 'CITE JEANNE D ARC ECRAN B2-GAMBETTA - ORAN', '0561724538', '0561724538',NULL,t_set_ref_vehicule());



-- Insérer les données dans la table employer

INSERT INTO employer VALUES (53, 'LACHEMI', 'Bouzid', 'Mécanicien', 25000,t_set_ref_intervenant());

INSERT INTO employer VALUES (54, 'BOUCHEMLA', 'Elias', 'Assistant', 10000,t_set_ref_intervenant());

INSERT INTO employer VALUES (55, 'HADJ', 'Zouhir', 'Assistant', 12000,t_set_ref_intervenant());

INSERT INTO employer VALUES (56, 'OUSSEDIK', 'Hakim', 'Mécanicien', 20000,t_set_ref_intervenant());

INSERT INTO employer VALUES (57, 'ABAD', 'Abdelhamid', 'Assistant', 13000,t_set_ref_intervenant());

INSERT INTO employer VALUES (58, 'BABACI', 'Tayeb', 'Mécanicien', 21300,t_set_ref_intervenant());

INSERT INTO employer VALUES (59, 'BELHAMIDI', 'Mourad', 'Mécanicien', 19500,t_set_ref_intervenant());

INSERT INTO employer VALUES (60, 'IGOUDJIL', 'Redouane', 'Assistant', 15000,t_set_ref_intervenant());

INSERT INTO employer VALUES (61, 'KOULA', 'Bahim', 'Mécanicien', 23100,t_set_ref_intervenant());

INSERT INTO employer VALUES (62, 'RAHALI', 'Ahcene', 'Mécanicien', 24000,t_set_ref_intervenant());

INSERT INTO employer VALUES (63, 'CHAOUI', 'Ismail', 'Assistant', 13000,t_set_ref_intervenant());

INSERT INTO employer VALUES (64, 'BADI', 'Hatem', 'Assistant', 14000,t_set_ref_intervenant());

INSERT INTO employer VALUES (65, 'MOHAMMEDI', 'Mustapha', 'Mécanicien', 24000,t_set_ref_intervenant());

INSERT INTO employer VALUES (66, 'FEKAR', 'Abdelaziz', 'Assistant', 13500,t_set_ref_intervenant());

INSERT INTO employer VALUES (67, 'SAIDOUNI', 'Wahid', 'Mécanicien', 25000,t_set_ref_intervenant());

INSERT INTO employer VALUES (68, 'BOULARAS', 'Farid', 'Assistant', 14000,t_set_ref_intervenant());
 
INSERT INTO employer VALUES (69, 'CHAKER', 'Nassim', 'Mécanicien', 26000,t_set_ref_intervenant());

INSERT INTO employer VALUES (71, 'TERKI', 'Yacine', 'Mécanicien', 23000,t_set_ref_intervenant());

INSERT INTO employer VALUES (72, 'TEBIBEL', 'Ahmed','Assistant', 17000,t_set_ref_intervenant());

INSERT INTO employer VALUES (80, 'LARDJOUNE', 'Karim', NULL , 25000,t_set_ref_intervenant());


-- Insérer les données dans la table marque

INSERT INTO marque VALUES (1, 'LAMBORGHINI', 'ITALIE',t_set_ref_modele());

INSERT INTO marque VALUES (2, 'AUDI', 'ALLEMAGNE',t_set_ref_modele());

INSERT INTO marque VALUES (3, 'ROLLS-ROYCE', 'GRANDE-BRETAGNE',t_set_ref_modele());

INSERT INTO marque VALUES (4, 'BMW', 'ALLEMAGNE',t_set_ref_modele());

INSERT INTO marque VALUES (5, 'CADILLAC', 'ETATS-UNIS',t_set_ref_modele());

INSERT INTO marque VALUES (6, 'CHRYSLER', 'ETATS-UNIS',t_set_ref_modele());

INSERT INTO marque VALUES (7, 'FERRARI', 'ITALIE',t_set_ref_modele());

INSERT INTO marque VALUES (8, 'HONDA', 'JAPON',t_set_ref_modele());

INSERT INTO marque VALUES (9, 'JAGUAR', 'GRANDE-BRETAGNE',t_set_ref_modele());

INSERT INTO marque VALUES (10, 'ALFA-ROMEO', 'ITALIE',t_set_ref_modele());

INSERT INTO marque VALUES (11, 'LEXUS', 'JAPON',t_set_ref_modele());

INSERT INTO marque VALUES (12, 'LOTUS', 'GRANDE-BRETAGNE',t_set_ref_modele());

INSERT INTO marque VALUES (13, 'MASERATI', 'ITALIE',t_set_ref_modele());
 
INSERT INTO marque VALUES (14, 'MERCEDES', 'ALLEMAGNE',t_set_ref_modele());

INSERT INTO marque VALUES (15, 'PEUGEOT', 'FRANCE',t_set_ref_modele());

INSERT INTO marque VALUES (16, 'PORSCHE', 'ALLEMAGNE',t_set_ref_modele());

INSERT INTO marque VALUES (17, 'RENAULT', 'FRANCE',t_set_ref_modele());

INSERT INTO marque VALUES (18, 'SAAB', 'SUEDE',t_set_ref_modele());

INSERT INTO marque VALUES (19, 'TOYOTA', 'JAPON',t_set_ref_modele());

INSERT INTO marque VALUES (20, 'VENTURI', 'FRANCE',t_set_ref_modele());

INSERT INTO marque VALUES (21, 'VOLVO', 'SUEDE',t_set_ref_modele());


-- Insérer les données dans la table modele


INSERT INTO modele VALUES (2, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 1), 'Diablo',t_set_ref_vehicule());

INSERT INTO modele VALUES (3, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 2), 'Série 5',t_set_ref_vehicule());

INSERT INTO modele VALUES (4, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 10), 'NSX',t_set_ref_vehicule());

INSERT INTO modele VALUES (5, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 14), 'Classe C',t_set_ref_vehicule());

INSERT INTO modele VALUES (6, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 17), 'Safrane',t_set_ref_vehicule());

INSERT INTO modele VALUES (7, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 20), '400 GT',t_set_ref_vehicule());

INSERT INTO modele VALUES (8, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 12), 'Esprit',t_set_ref_vehicule());

INSERT INTO modele VALUES (9, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 15), '605',t_set_ref_vehicule());

INSERT INTO modele VALUES (10, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 19), 'Prévia',t_set_ref_vehicule());

INSERT INTO modele VALUES (11, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 7), '550 Maranello',t_set_ref_vehicule());

INSERT INTO modele VALUES (12, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 3), 'Bentley-Continental',t_set_ref_vehicule());

INSERT INTO modele VALUES (13, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 10), 'Spider',t_set_ref_vehicule());

INSERT INTO modele VALUES (14, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 13), 'Evoluzione',t_set_ref_vehicule());

INSERT INTO modele VALUES (15, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 16), 'Carrera',t_set_ref_vehicule());

INSERT INTO modele VALUES (16, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 16), 'Boxter',t_set_ref_vehicule());

INSERT INTO modele VALUES (17, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 21), 'S 80',t_set_ref_vehicule());

INSERT INTO modele VALUES (18, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 6), '300 M',t_set_ref_vehicule());

INSERT INTO modele VALUES (19, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 4), 'M 3',t_set_ref_vehicule());

INSERT INTO modele VALUES (20, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 9), 'XJ 8',t_set_ref_vehicule());

INSERT INTO modele VALUES (21, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 15), '406 Coupé',t_set_ref_vehicule());

INSERT INTO modele VALUES (22, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 20), '300 Atlantic',t_set_ref_vehicule());

INSERT INTO modele VALUES (23, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 14), 'Classe E',t_set_ref_vehicule());

INSERT INTO modele VALUES (24, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 11), 'GS 300',t_set_ref_vehicule());

INSERT INTO modele VALUES (25, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 5), 'Séville',t_set_ref_vehicule());

INSERT INTO modele VALUES (26, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 18), '95 Cabriolet',t_set_ref_vehicule());

INSERT INTO modele VALUES (27, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 2), 'TT Coupè',t_set_ref_vehicule());

INSERT INTO modele VALUES (28, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 7), 'F 355',t_set_ref_vehicule());

INSERT INTO modele VALUES (29, (SELECT REF(m) FROM marque m WHERE NUMMARQUE = 4), 'POLO',t_set_ref_vehicule());





-- Insérer les données dans la table vehicule

INSERT INTO vehicule VALUES (1, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 2), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 6), '0012519216', 1992,t_set_ref_intervention());

INSERT INTO vehicule VALUES (2, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 9), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 20), '0124219316', 1993,t_set_ref_intervention());

INSERT INTO vehicule VALUES (3, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 17), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 8), '1452318716', 1987,t_set_ref_intervention());

INSERT INTO vehicule VALUES (4, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 6), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 12), '3145219816', 1998,t_set_ref_intervention());

INSERT INTO vehicule VALUES (5, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 16), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 23), '1278919816', 1998,t_set_ref_intervention());

INSERT INTO vehicule VALUES (6, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 20), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 6), '3853319735', 1997,t_set_ref_intervention());

INSERT INTO vehicule VALUES (7, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 7), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 8), '1453119816', 1998,t_set_ref_intervention());

INSERT INTO vehicule VALUES (8, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 16), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 14), '8365318601', 1986,t_set_ref_intervention());

INSERT INTO vehicule VALUES (9, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 13), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 15), '3087319233', 1992,t_set_ref_intervention());

INSERT INTO vehicule VALUES (10, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 20), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 22), '9413119935', 1999,t_set_ref_intervention());

INSERT INTO vehicule VALUES (11, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 9), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 16), '1572319801', 1998,t_set_ref_intervention());

INSERT INTO vehicule VALUES (12, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 14), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 20), '6025319733', 1997,t_set_ref_intervention());

INSERT INTO vehicule VALUES (13, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 19), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 17), '5205319736', 1997,t_set_ref_intervention());

INSERT INTO vehicule VALUES (14, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 22), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 21), '7543119207', 1992,t_set_ref_intervention());

INSERT INTO vehicule VALUES (15, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 4), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 19), '6254319916', 1999,t_set_ref_intervention());

INSERT INTO vehicule VALUES (16, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 16), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 21), '9831419701', 1997,t_set_ref_intervention());

INSERT INTO vehicule VALUES (17, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 12), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 11), '4563117607', 1976,t_set_ref_intervention());

INSERT INTO vehicule VALUES (18, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 1), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 2), '7973318216', 1982,t_set_ref_intervention());

INSERT INTO vehicule VALUES (19, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 18), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 77), '3904318515', 1985,t_set_ref_intervention());

INSERT INTO vehicule VALUES (20, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 22), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 2), '1234319707', 1997,t_set_ref_intervention());

INSERT INTO vehicule VALUES (21, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 3), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 19), '8429318516', 1985,t_set_ref_intervention());

INSERT INTO vehicule VALUES (22, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 8), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 19), '1245619816', 1998,t_set_ref_intervention());

INSERT INTO vehicule VALUES (23, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 7), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 25), '1678918516', 1985,t_set_ref_intervention());

INSERT INTO vehicule VALUES (24, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 8), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 9), '1789519816', 1998,t_set_ref_intervention());

INSERT INTO vehicule VALUES (25, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 13), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 5), '1278919833', 1998,t_set_ref_intervention());

INSERT INTO vehicule VALUES (26, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 3), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 10), '1458919316', 1993,t_set_ref_intervention());

INSERT INTO vehicule VALUES (27, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 10), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 7), '1256019804', 1998,t_set_ref_intervention());

INSERT INTO vehicule VALUES (28, (SELECT REF(c) FROM client c WHERE C.NUMCLIENT = 10), (SELECT REF(M) FROM MODELE M WHERE m.NUMMODELE = 3), '1986219904', 1999,t_set_ref_intervention());



-- Insérer les données dans la table intervention

INSERT INTO intervention VALUES (1, (SELECT REF(v) FROM vehicule v WHERE v.NUMVEHICULE = 3), 'Réparation', TO_DATE('2006-02-25 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-02-26 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 30000,t_set_ref_intervenant());

INSERT INTO intervention VALUES (2, (SELECT REF(v) FROM vehicule v WHERE v.NUMVEHICULE = 21), 'Réparation', TO_DATE('2006-02-23 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-02-24 18:00:00', 'YYYY-MM-DD HH24:MI:SS'), 10000,t_set_ref_intervenant());

INSERT INTO intervention VALUES (3, (SELECT REF(v) FROM vehicule v WHERE v.NUMVEHICULE = 25), 'Réparation', TO_DATE('2006-04-06 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-04-09 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 42000,t_set_ref_intervenant());

INSERT INTO intervention VALUES (4, (SELECT REF(v) FROM vehicule v WHERE v.NUMVEHICULE = 10), 'Entretien', TO_DATE('2006-05-14 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-05-14 18:00:00', 'YYYY-MM-DD HH24:MI:SS'), 10000,t_set_ref_intervenant());

INSERT INTO intervention VALUES (5, (SELECT REF(v) FROM vehicule v WHERE v.NUMVEHICULE = 6), 'Réparation', TO_DATE('2006-02-22 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-02-25 18:00:00', 'YYYY-MM-DD HH24:MI:SS'), 40000,t_set_ref_intervenant());

INSERT INTO intervention VALUES (6, (SELECT REF(v) FROM vehicule v WHERE v.NUMVEHICULE = 14), 'Entretien', TO_DATE('2006-03-03 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-03-04 18:00:00', 'YYYY-MM-DD HH24:MI:SS'), 7500,t_set_ref_intervenant());

INSERT INTO intervention VALUES (7, (SELECT REF(v) FROM vehicule v WHERE v.NUMVEHICULE = 1), 'Entretien', TO_DATE('2006-04-09 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-04-09 18:00:00', 'YYYY-MM-DD HH24:MI:SS'), 8000,t_set_ref_intervenant());

INSERT INTO intervention VALUES (8, (SELECT REF(v) FROM vehicule v WHERE v.NUMVEHICULE = 17), 'Entretien', TO_DATE('2006-05-11 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-05-12 18:00:00', 'YYYY-MM-DD HH24:MI:SS'), 9000,t_set_ref_intervenant());

INSERT INTO intervention VALUES (9, (SELECT REF(v) FROM vehicule v WHERE v.NUMVEHICULE = 22), 'Entretien', TO_DATE('2006-02-22 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-02-22 18:00:00', 'YYYY-MM-DD HH24:MI:SS'), 7960,t_set_ref_intervenant());

INSERT INTO intervention VALUES (10, (SELECT REF(v) FROM vehicule v WHERE v.NUMVEHICULE = 2), 'Entretien et Réparation', TO_DATE('2006-04-08 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-04-09 18:00:00', 'YYYY-MM-DD HH24:MI:SS'), 45000,t_set_ref_intervenant());

INSERT INTO intervention VALUES (11, (SELECT REF(v) FROM vehicule v WHERE v.NUMVEHICULE = 28), 'Réparation', TO_DATE('2006-03-08 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-03-17 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 36000,t_set_ref_intervenant());

INSERT INTO intervention VALUES (12, (SELECT REF(v) FROM vehicule v WHERE v.NUMVEHICULE = 20), 'Entretien et Réparation', TO_DATE('2006-05-03 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-05-05 18:00:00', 'YYYY-MM-DD HH24:MI:SS'), 27000,t_set_ref_intervenant());

INSERT INTO intervention VALUES (13, (SELECT REF(v) FROM vehicule v WHERE v.NUMVEHICULE = 8), 'Réparation Système', TO_DATE('2006-05-12 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-05-12 18:00:00', 'YYYY-MM-DD HH24:MI:SS'), 17846,t_set_ref_intervenant());

INSERT INTO intervention VALUES (14, (SELECT REF(v) FROM vehicule v WHERE v.NUMVEHICULE = 1), 'Réparation', TO_DATE('2006-05-10 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-05-12 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 39000,t_set_ref_intervenant());

INSERT INTO intervention VALUES (15, (SELECT REF(v) FROM vehicule v WHERE v.NUMVEHICULE = 20), 'Réparation Système', TO_DATE('2006-06-25 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-06-25 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 27000,t_set_ref_intervenant());

INSERT INTO intervention VALUES (16, (SELECT REF(v) FROM vehicule v WHERE v.NUMVEHICULE = 7), 'Réparation', TO_DATE('2006-06-27 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-06-30 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 25000,t_set_ref_intervenant());


-- Insérer les données dans la table intervenant

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 1), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 54), TO_DATE('2006-02-26 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-02-26 12:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 1), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 59), TO_DATE('2006-02-25 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-02-25 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 2), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 57), TO_DATE('2006-02-24 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-02-24 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 2), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 59), TO_DATE('2006-02-23 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-02-24 12:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 3), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 60), TO_DATE('2006-04-09 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-04-09 12:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 3), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 65), TO_DATE('2006-04-06 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-04-08 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 4), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 62), TO_DATE('2006-05-14 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-05-14 12:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 4), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 66), TO_DATE('2006-02-14 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-05-14 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 5), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 56), TO_DATE('2006-02-22 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-02-25 12:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 5), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 60), TO_DATE('2006-02-23 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-02-25 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 6), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 53), TO_DATE('2006-03-03 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-03-04 12:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 6), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 57), TO_DATE('2006-03-04 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-03-04 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 7), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 55), TO_DATE('2006-04-09 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-04-09 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 7), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 65), TO_DATE('2006-04-09 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-04-09 12:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 8), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 54), TO_DATE('2006-05-12 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-05-12 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 8), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 62), TO_DATE('2006-05-11 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-05-12 12:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 9), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 59), TO_DATE('2006-02-22 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-02-22 12:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 9), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 60), TO_DATE('2006-02-22 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-02-22 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 10), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 63), TO_DATE('2006-04-09 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-04-09 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 10), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 67), TO_DATE('2006-04-08 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-04-09 12:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 11), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 59), TO_DATE('2006-03-09 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-03-11 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 11), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 64), TO_DATE('2006-03-09 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-03-17 12:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 11), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 53), TO_DATE('2006-03-08 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-03-16 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 12), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 55), TO_DATE('2006-05-05 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-05-05 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 12), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 56), TO_DATE('2006-05-03 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-05-05 12:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 13), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 64), TO_DATE('2006-05-12 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-05-12 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO intervenant VALUES ((SELECT REF(I) FROM intervention I WHERE I.NUMINTERVENTION = 14), (SELECT REF(e) FROM employer e WHERE e.NUMEMPLOYER = 88), TO_DATE('2006-05-07 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2006-05-10 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));



-- rajouter les références des vihicules dans la collection client_vhecule

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =1) VALUES((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =18));

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =2) VALUES((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =1));

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =3) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE=21));
INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =3) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE=26));

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =4) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =15));

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =6) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =4));

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =7) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =7));
INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =7) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =23));

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =8) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =22));
INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =8) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =24));

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =9) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =2));
INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =9) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =11));

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =10) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =27));
INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =10) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =28));

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =12) VALUES (SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =17);

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =13) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =9));
INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =13) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =25));

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =14) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =12));

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =16) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =5)):
INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =16) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =16)):

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =17) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =3));

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =18) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =19));

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =19) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =13));

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =20) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =6));
INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =20) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =10));

INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =22) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =14));
INSERT INTO table (SELECT c.client_vehicule FROM client c WHERE c.NUMCLIENT =22) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =20));


-- rajouter les références des modeles dans la collection marque_modele

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =1) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =2));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =2) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =3));
INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =2) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =27));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =3) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =12));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =4) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =19));
INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =4) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =29));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =5) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =25));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =6) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =18));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =7) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =11));
INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =7) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =28));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =9) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =20));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =10) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =4));
INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =10) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =13));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =11) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =24));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =12) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =8));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =13) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =14));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =14) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =5));
INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =14) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =23));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =15) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =9));
INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =15) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =21));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =16) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =15));
INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =16) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =16));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =17) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =6));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =18) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =26));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =19) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =10));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =20) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =7));
INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =20) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =22));

INSERT INTO table (SELECT ma.MARQUE_MODELE FROM marque ma WHERE ma.NUMMARQUE =21) VALUES ((SELECT REF(mo) FROM modele mo WHERE NUMMODELE =17));



-- rajouter les références des vehicules dans la collection modele_vehicule

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =2) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =18));
INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =2) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =20));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =3) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =28));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =5) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =25));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =6) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =1));
INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =6) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =6));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =7) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =19));
INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =7) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =27));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =8) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =3));
INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =8) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =7));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =9) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =24));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =10) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =26));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =11) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =17));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =12) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =4));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =14) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =8));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =15) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =9));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =16) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =11));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =17) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =13));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =19) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =21));
INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =19) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =22));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =20) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =2));
INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =20) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =12));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =21) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =14));
INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =21) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =16));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =22) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =10));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =23) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =5));

INSERT INTO table (SELECT m.modele_vehicule FROM modele m WHERE m.NUMMODELE =25) VALUES ((SELECT REF(v) FROM vehicule v WHERE NUMVEHICULE =23));


-- rajouter les références des interventions dans la collection vehicule_intervention

INSERT INTO table (SELECT v.vehicule_intervention FROM vehicule v WHERE v.NUMVEHICULE =1) VALUES ((SELECT REF(i) FROM intervention i WHERE NUMINTERVENTION=7));
INSERT INTO table (SELECT v.vehicule_intervention FROM vehicule v WHERE v.NUMVEHICULE =1) VALUES ((SELECT REF(i) FROM intervention i WHERE NUMINTERVENTION=14));

INSERT INTO table (SELECT v.vehicule_intervention FROM vehicule v WHERE v.NUMVEHICULE =2) VALUES ((SELECT REF(i) FROM intervention i WHERE NUMINTERVENTION=10));

INSERT INTO table (SELECT v.vehicule_intervention FROM vehicule v WHERE v.NUMVEHICULE =3) VALUES ((SELECT REF(i) FROM intervention i WHERE NUMINTERVENTION=1));

INSERT INTO table (SELECT v.vehicule_intervention FROM vehicule v WHERE v.NUMVEHICULE =6) VALUES ((SELECT REF(i) FROM intervention i WHERE NUMINTERVENTION=5));

INSERT INTO table (SELECT v.vehicule_intervention FROM vehicule v WHERE v.NUMVEHICULE =7) VALUES ((SELECT REF(i) FROM intervention i WHERE NUMINTERVENTION=16));

INSERT INTO table (SELECT v.vehicule_intervention FROM vehicule v WHERE v.NUMVEHICULE =8) VALUES ((SELECT REF(i) FROM intervention i WHERE NUMINTERVENTION=13));

INSERT INTO table (SELECT v.vehicule_intervention FROM vehicule v WHERE v.NUMVEHICULE =10) VALUES ((SELECT REF(i) FROM intervention i WHERE NUMINTERVENTION=4));

INSERT INTO table (SELECT v.vehicule_intervention FROM vehicule v WHERE v.NUMVEHICULE =14) VALUES ((SELECT REF(i) FROM intervention i WHERE NUMINTERVENTION=6));

INSERT INTO table (SELECT v.vehicule_intervention FROM vehicule v WHERE v.NUMVEHICULE =17) VALUES ((SELECT REF(i) FROM intervention i WHERE NUMINTERVENTION=8));

INSERT INTO table (SELECT v.vehicule_intervention FROM vehicule v WHERE v.NUMVEHICULE =20) VALUES ((SELECT REF(i) FROM intervention i WHERE NUMINTERVENTION=12));
INSERT INTO table (SELECT v.vehicule_intervention FROM vehicule v WHERE v.NUMVEHICULE =20) VALUES ((SELECT REF(i) FROM intervention i WHERE NUMINTERVENTION=15));

INSERT INTO table (SELECT v.vehicule_intervention FROM vehicule v WHERE v.NUMVEHICULE =21) VALUES ((SELECT REF(i) FROM intervention i WHERE NUMINTERVENTION=2));

INSERT INTO table (SELECT v.vehicule_intervention FROM vehicule v WHERE v.NUMVEHICULE =22) VALUES ((SELECT REF(i) FROM intervention i WHERE NUMINTERVENTION=9));

INSERT INTO table (SELECT v.vehicule_intervention FROM vehicule v WHERE v.NUMVEHICULE =25) VALUES ((SELECT REF(i) FROM intervention i WHERE NUMINTERVENTION=3));

INSERT INTO table (SELECT v.vehicule_intervention FROM vehicule v WHERE v.NUMVEHICULE =28) VALUES ((SELECT REF(i) FROM intervention i WHERE NUMINTERVENTION=11));


-- rajouter les références des intervenants dans la collection employe_intervenants


insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=54) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=1));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=59) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=1));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=57) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=2));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=59) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=2));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=60) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=3));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=65) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=3));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=66) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=4));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=62) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=4));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=60) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=5));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=56) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=5));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=53) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=6));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=57) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=6));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=55) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=7));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=65) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=7));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=62) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=8));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=54) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=8));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=60) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=9));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=59) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=9));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=63) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=10));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=67) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=10));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=64) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=11));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=53) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=11));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=59) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=11));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=55) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=12));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=56) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=12));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=64) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=13));

insert into table(select e.employer_intervenant from employer e  where e.NUMEMPLOYER=80) ((select ref(i) from intervenant i where deref(NUMINTERVENTION).NUMINTERVENTION=14));



-- rajouter les références des intervenants dans la collection intervention_intervenants


insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=1) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=54));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=1) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=59));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=2) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=57));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=2) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=59));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=3) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=60));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=3) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=65));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=4) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=62));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=4) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=66));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=5) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=56));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=5) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=60));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=6) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=53));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=6) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=57));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=7) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=55));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=7) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=65));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=8) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=54));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=8) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=62));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=9) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=59));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=9) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=60));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=10) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=63));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=10) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=67));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=11) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=59));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=11) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=64));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=11) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=53));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=12) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=59));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=12) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=56));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=13) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=64));

insert into table(select i.intervention_intervenant from intervention i  where i.NUMINTERVENTION=14) ((select ref(i) from intervenant i where deref(NUMEMPLOYE).NUMEMPLOYER=80));


-- ********* E- Langage d’interrogation de données :**********

-- 9-

SELECT DEREF(m.NUMMARQUE).MARQUE AS MARQUE, -- Sélectionne le nom de la marque associée à chaque modèle
       m.MODELE AS MODELE -- Sélectionne le nom du modèle lui-même
FROM modele m; -- Sélectionne depuis la table des modèles

-- 10-

-- Sélectionne le numéro de véhicule pour les véhicules sur lesquels il y a au moins une intervention
SELECT v.NUMVEHICULE
FROM vehicule v
-- Vérifie s'il existe au moins une intervention associée à chaque véhicule
WHERE EXISTS (
    -- Sous-requête : sélectionne le nombre 1 si une intervention existe pour le véhicule en cours d'évaluation
    SELECT 1
    FROM intervention i
    -- Condition : vérifie si la référence du véhicule dans l'intervention correspond à la référence du véhicule dans la table principale
    WHERE i.NUMVEHICULE = REF(v)
);


-- 11-

-- Sélectionne la durée moyenne des interventions
SELECT 
    AVG(DATEFININTRV - DATEDEBINTRV) AS duree_moyenne_intervention
    -- Calcul de la différence entre la date de fin et la date de début de chaque intervention
    -- La différence est calculée en soustrayant la date de début (DATEDEBINTRV) de la date de fin (DATEFININTRV)
    -- Cette opération donne la durée de chaque intervention en jours (car les colonnes sont de type DATE)
-- À partir de la table intervention
FROM 
    intervention;
    -- Sélection de la table intervention où sont stockées les informations sur les interventions


-- 12-

-- Sélectionne la somme des coûts d'intervention dont le coût est supérieur à 30000 DA
SELECT SUM(COUTINTERV) AS Montant_Global  -- La fonction SUM() calcule la somme des valeurs de la colonne COUTINTERV
FROM intervention  -- Spécifie la table à partir de laquelle les données sont sélectionnées (intervention)
WHERE COUTINTERV > 30000;  -- Filtre les lignes pour inclure uniquement celles où le coût d'intervention est supérieur à 30000 DA


-- 13-

SELECT 
    e.NUMEMPLOYER, -- Sélectionne le numéro de l'employé
    e.NOMEMP, -- Sélectionne le nom de l'employé
    e.PRENOMEMP, -- Sélectionne le prénom de l'employé
    e.CATEGORIE, -- Sélectionne la catégorie de l'employé
    COUNT(DISTINCT DEREF(it.NUMINTERVENTION).NUMINTERVENTION) AS NB_INTERVENTIONS -- Compte le nombre d'interventions distinctes effectuées par l'employé
FROM 
    employer e, -- Sélectionne à partir de la table des employés
    intervenant it, -- Sélectionne à partir de la table des intervenants
    intervention i -- Sélectionne à partir de la table des interventions
WHERE 
    e.NUMEMPLOYER = it.NUMEMPLOYE.NUMEMPLOYER -- Fait correspondre l'employé avec l'intervenant
    AND DEREF(it.NUMINTERVENTION).NUMVEHICULE = i.NUMVEHICULE -- Fait correspondre l'intervention avec le véhicule
GROUP BY 
    e.NUMEMPLOYER, e.NOMEMP, e.PRENOMEMP, e.CATEGORIE -- Regroupe les résultats par employé
ORDER BY 
    NB_INTERVENTIONS DESC; -- Trie les résultats par nombre d'interventions décroissant


SELECT p.*
FROM EMPLOYER p 
WHERE p.employer_intervenant IS NOT EMPTY;