DROP FUNCTION IF EXISTS calcul_nb_ligne_par_date;
DELIMITER $$
CREATE FUNCTION calcul_nb_ligne_par_date(jour DATE)
RETURNS INTEGER
BEGIN 
  DECLARE quantity INTEGER;
	SET quantity = (SELECT count(*) FROM table_mechanical_assembly where MA_date = jour);
  RETURN quantity;
END$$
DELIMITER ;

########################################################### Appelation fonction #########################################################
select calcul_nb_ligne_par_date('2021-11-25');
#########################################################################################################################################

DROP FUNCTION IF EXISTS MA_start_time_par_ligne;
DELIMITER $$
CREATE FUNCTION MA_start_time_par_ligne(jour DATE, nb_jour INTEGER)
RETURNS time
BEGIN 
  DECLARE heure TIME;
	SET heure = (SELECT MA_start_time FROM table_mechanical_assembly where MA_date = jour LIMIT nb_jour,1);
  RETURN heure;
END$$
DELIMITER ;

########################################################### Appelation fonction #########################################################
SELECT MA_start_time_par_ligne('2021-11-20', 12); 
#########################################################################################################################################

DROP FUNCTION IF EXISTS Calcul_temps_boucle;
DELIMITER $$
CREATE FUNCTION Calcul_temps_boucle(jour DATE, taille INTEGER)
RETURNS INTEGER
BEGIN 
	DECLARE i, somme integer default 0;   
    DECLARE difference integer;
    DECLARE start_time_i, start_time_j time;
	WHILE i < taille-1 DO
    	SET start_time_i = MA_start_time_par_ligne(jour , i);
		SET start_time_j = MA_start_time_par_ligne(jour , i + 1);
        SET difference = TIME_TO_SEC(start_time_j) - TIME_TO_SEC(start_time_i);
		SET somme = somme + difference; 
        SET i = i + 1;
	END WHILE;
    RETURN somme;    
END$$
DELIMITER ;

########################################################### Appelation fonction #########################################################
select Calcul_temps_boucle('2021-11-20', 2);
#########################################################################################################################################

DROP FUNCTION IF EXISTS  diff_fin_deb;
DELIMITER $$
CREATE FUNCTION  diff_fin_deb(jour DATE, nb_total INTEGER)
RETURNS INTEGER
BEGIN 
	SET @debut = (SELECT MA_start_time as debut FROM table_mechanical_assembly where MA_date = jour LIMIT 0,1);
    SET @fin   = (SELECT MA_start_time as fin FROM table_mechanical_assembly where MA_date = jour LIMIT nb_total, 1);
	RETURN TIME_TO_SEC(TIMEDIFF(@fin, @debut));
END$$
DELIMITER ;

########################################################### Appelation fonction #########################################################
SELECT diff_fin_deb ('2021-11-20', 200);
#########################################################################################################################################

DROP PROCEDURE IF EXISTS nb_second_par_jour;
DELIMITER $$
CREATE PROCEDURE nb_second_par_jour (jour DATE)
BEGIN 
	SET @nb_total := calcul_nb_ligne_par_date(jour) ;
	SELECT jour as Jour, 
		   @nb_total as taille_BD,
		   Diff_fin_deb (jour, @nb_total-1), 
		   Calcul_temps_boucle(jour, @nb_total) ;
END$$
DELIMITER ;

########################################################### Appelation procedure ########################################################
CALL nb_second_par_jour('2021-11-25')
#########################################################################################################################################