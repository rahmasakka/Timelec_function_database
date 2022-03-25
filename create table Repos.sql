################################################################# table repos ###########################################################
DROP table timelec_database.repos;
Create table Repos(
   ID_mechanical_assembly long, 
   Tester_ID int, 
   Test_status boolean, 
   Test_start_time timestamp
);
############################################################### table production #########################################################
DROP table timelec_database.production;
Create table production(
   ID_mechanical_assembly long, 
   Tester_ID int, 
   Test_status boolean, 
   Test_start_time timestamp
);
##################################################################### view ###############################################################
DROP VIEW IF EXISTS testeur;
CREATE VIEW testeur AS
		SELECT Table_mechanical_assembly_ID_mechanical_assembly, Tester_ID, Test_status, Test_start_time 
		FROM test_results_vm.table_summary 
		WHERE tester_ID = 6932 AND CONVERT(Test_start_time, DATE) = '2020-11-30';
###########################################################################################################################################
DROP FUNCTION IF EXISTS calcul_nb_operation_par_jour;
DELIMITER $$
CREATE FUNCTION calcul_nb_operation_par_jour(jour DATE, testerID INTEGER)
RETURNS INTEGER
BEGIN 
  DECLARE quantity INTEGER;
	SET quantity = (
		SELECT count(*) 
		FROM testeur
		WHERE CONVERT(Test_start_time, DATE) = jour AND Tester_ID = testerID
        );
  RETURN quantity;
END$$
DELIMITER ;
########################################################### Appelation fonction #########################################################
select calcul_nb_operation_par_jour('2016-11-30', 6932);
#########################################################################################################################################
DROP FUNCTION IF EXISTS start_time_par_operation;
DELIMITER $$
CREATE FUNCTION start_time_par_operation(date DATE, nb_jour INTEGER, testerID INTEGER)
RETURNS time
BEGIN 
  DECLARE heure TIME;
	SET heure = (
		SELECT CONVERT (Test_start_time, TIME)
        FROM testeur
        WHERE CONVERT (Test_start_time, DATE) = date AND Tester_ID = testerID
        LIMIT nb_jour,1
        );
  RETURN heure;
END$$
DELIMITER ;
########################################################### Appelation fonction #########################################################
#SELECT start_time_par_operation('2016-11-30', 5, 6932); 
#########################################################################################################################################

DROP FUNCTION IF EXISTS Calcul_temps_boucle;
DELIMITER $$
CREATE FUNCTION Calcul_temps_boucle(jour DATE, taille INTEGER, testerID INTEGER)
RETURNS INTEGER
BEGIN 
	DECLARE i, somme integer default 0;   
    DECLARE difference integer;
    DECLARE start_time_i, start_time_j time;
	WHILE i < taille DO
    	SET start_time_i = start_time_par_operation(jour, i, testerID);
		SET start_time_j = start_time_par_operation(jour, i + 1, testerID);
        SET difference = TIME_TO_SEC(start_time_j) - TIME_TO_SEC(start_time_i);
		SET somme = somme + difference; 
        IF (difference > 5 * 60) THEN
            INSERT INTO timelec_database.repos 
            SELECT Table_mechanical_assembly_ID_mechanical_assembly, Tester_ID, Test_status, Test_start_time 
			FROM testeur
			WHERE tester_ID = testerID AND CONVERT(Test_start_time, DATE) = jour
            LIMIT i,1;
		ELSE 
			INSERT INTO timelec_database.production 
            SELECT Table_mechanical_assembly_ID_mechanical_assembly, Tester_ID, Test_status, Test_start_time 
			FROM testeur
			WHERE tester_ID = testerID AND CONVERT(Test_start_time, DATE) = jour
            LIMIT i,1;
        END IF;
        SET i = i + 1;
	END WHILE;
	SET start_time_i = start_time_par_operation(jour, i, testerID);
	SET start_time_j = start_time_par_operation(jour, i + 1, testerID);
	SET difference = TIME_TO_SEC(start_time_j) - TIME_TO_SEC(start_time_i);
	IF (difference > 5 * 60) THEN
		INSERT INTO timelec_database.repos 
		SELECT Table_mechanical_assembly_ID_mechanical_assembly, Tester_ID, Test_status, Test_start_time 
		FROM testeur
		WHERE tester_ID = testerID AND CONVERT(Test_start_time, DATE) = jour
		LIMIT i,1;
	ELSE 
		INSERT INTO timelec_database.production 
		SELECT Table_mechanical_assembly_ID_mechanical_assembly, Tester_ID, Test_status, Test_start_time 
		FROM testeur
		WHERE tester_ID = testerID AND CONVERT(Test_start_time, DATE) = jour
		LIMIT i,1;
	END IF;

    RETURN somme;    
END$$
DELIMITER ;
########################################################### Appelation fonction #########################################################
#SELECT Calcul_temps_boucle('2016-11-30', 1, 6932); 
#########################################################################################################################################
DROP FUNCTION IF EXISTS diff_fin_deb;
DELIMITER $$
CREATE FUNCTION diff_fin_deb(jour DATE, nb_total INTEGER, testerID INTEGER)
RETURNS INTEGER
BEGIN 
	SET @debut = (
		SELECT CONVERT(Test_start_time, TIME)
        FROM testeur
        WHERE CONVERT(Test_start_time, DATE) = jour AND Tester_ID = testerID
        LIMIT 0,1
        );
    SET @fin = (
		SELECT CONVERT(Test_start_time, TIME) 
		FROM testeur
        WHERE CONVERT(Test_start_time, DATE) = jour AND Tester_ID = testerID
        LIMIT nb_total, 1
        );
	RETURN TIME_TO_SEC(TIMEDIFF(@fin, @debut));
END$$
DELIMITER ;
########################################################### Appelation fonction #########################################################
#SELECT diff_fin_deb ('2016-11-30', 10, 6932);
#########################################################################################################################################
DROP PROCEDURE IF EXISTS nb_heure_par_jour;
DELIMITER $$
CREATE PROCEDURE nb_heure_par_jour (jour DATE, testerID INTEGER)
BEGIN 
	SET @nb_total := calcul_nb_operation_par_jour(jour, testerID);
	SELECT jour as Jour, 
		   @nb_total as taille_BD_par_jour,
           testerID,
		   Diff_fin_deb(jour,@nb_total-1, testerID) as Diff_fin_deb_second,
           SEC_TO_TIME(Diff_fin_deb(jour,@nb_total-1, testerID)) as Diff_fin_deb_heure,
		   Calcul_temps_boucle(jour,@nb_total-1, testerID) as Calcul_temps_boucle_second,
		   #SEC_TO_TIME(Calcul_temps_boucle(jour,@nb_total-1, testerID)) as Calcul_temps_boucle_heure,
		   SEC_TO_TIME(Diff_fin_deb(jour,@nb_total-1, testerID) div @nb_total) as Moyenne ; 
	END$$
DELIMITER ;           
########################################################### Appelation procedure ########################################################
CALL nb_heure_par_jour('2020-11-30', 6932);
################################################################## view #################################################################
SELECT count(*) FROM testeur;
SELECT * FROM testeur;
SELECT count(*) FROM timelec_database.repos;
SELECT * FROM timelec_database.repos;
SELECT count(*) FROM timelec_database.production;
SELECT * FROM timelec_database.production;