DROP FUNCTION IF EXISTS calcul_nb_ligne_par_date;
DELIMITER $$
CREATE FUNCTION calcul_nb_ligne_par_date(datee DATE)
RETURNS INTEGER
BEGIN 
  DECLARE quantity INTEGER;
	SET quantity = (SELECT count(*) FROM table_mechanical_assembly where MA_date=datee);
  RETURN quantity;
END$$
DELIMITER ;

########################################################### Appelation fonction #########################################################
select calcul_nb_ligne_par_date('2021-11-20');
#########################################################################################################################################

DROP FUNCTION IF EXISTS nb_second_par_ligne;
DELIMITER $$
CREATE FUNCTION nb_second_par_ligne(datee DATE, i int)
RETURNS time
BEGIN 
  DECLARE time1 time;
	SET time1 =  TIME_FORMAT((SELECT MA_start_time FROM table_mechanical_assembly where MA_date = datee LIMIT i,1), "%H:%i:%s");
  RETURN time1;
END$$
DELIMITER ;

########################################################### Appelation fonction #########################################################
SELECT nb_second_par_ligne('2021-11-20', 0); 
# la compare avec :
SELECT MA_start_time FROM table_mechanical_assembly where MA_date = '2021-11-20' LIMIT 0,1;
#########################################################################################################################################

DROP FUNCTION IF EXISTS Calcul_temps;
DELIMITER $$
CREATE FUNCTION Calcul_temps(datee date, n integer)
RETURNS integer
BEGIN 
	DECLARE i integer default 0;   
    DECLARE x time;
    DECLARE y time;
    DECLARE w integer default 0;
    #DECLARE z time default '00:00:00';    
	WHILE i < n-1 DO
    	set x = nb_second_par_ligne(datee,i);
		set y = nb_second_par_ligne(datee,i+1);
		set w = w + TIME_TO_SEC(y) - TIME_TO_SEC(x); 
        set i = i + 1;
	END WHILE;
    return w;    
END$$
DELIMITER ;

########################################################### Appelation fonction #########################################################
select Calcul_temps('2021-11-20', 1);
SET @nb_total := calcul_nb_ligne_par_date('2021-11-20') ;
select(@nb_total);
select Calcul_temps('2021-11-20', @nb_total);
#########################################################################################################################################

set @debut1 = (SELECT MA_start_time as debut1 FROM table_mechanical_assembly where MA_date = '2021-11-20' LIMIT 1,1);
set @fin1 = (SELECT MA_start_time as fin1 FROM table_mechanical_assembly where MA_date = '2021-11-20' LIMIT 530, 1);
SELECT TIME_TO_SEC(TIMEDIFF(@fin1, @debut1));