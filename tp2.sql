-- 1 preparation

set autotrace traceonly
SELECT ∗ FROM PERSON WHERE lastname LIKE 'L%' ;
--set autotrace off

-- 2 analyse des requetes
-- 2.1 plan d executio et trace
-- 2.2  Utilisation de l’optimiseur

-- optimiseur syntaxique
-- alter session set OPTIMIZER_MODE = RULE ;

-- optimiseur statistique
-- alter session set OPTIMIZER_MODE=ALL_ROWS ;

-- optimiseur statistique si les statistiques existent sinon syntaxique
-- alter session set OPTIMIZER_MODE=CHOOSE ;

--3 Analyse et comparaison des plans d execution

alter session set OPTIMIZER_MODE=ALL_ROWS ;

-- 1°/
SELECT * FROM MOVIE
	WHERE UPPER(GENDER) LIKE 'EPIC%';

-- 2°/
SELECT * FROM MOVIE
	WHERE GENDER IS NULL;

-- 3°/
SELECT TITLE FROM MOVIE
	WHERE RUNNING_TIME <= 130
	AND BUDGET > 50000000;

-- 4°/

select title from MOVIE
       where movie_id in (select movie_id from REVIEW
                                 where score_pct >= 70 and critic_number >= 100);

select title from MOVIE
       where movie_id in (select movie_id from REVIEW where score_pct >= 70)
       and   movie_id in (select movie_id from REVIEW where critic_number >= 100);

select title from MOVIE
       where movie_id in (select movie_id from REVIEW where score_pct >= 70)
INTERSECT
select title from MOVIE
       where movie_id in (select movie_id from REVIEW where critic_number >= 100);

select m.title from MOVIE m, REVIEW r
       where m.movie_id=r.movie_id
         and r.score_pct >= 70 and r.critic_number >= 100;

select title from MOVIE
       where movie_id = ANY
          (select movie_id from REVIEW
                  where score_pct >= 70 and critic_number >= 100);

select m.title from MOVIE m
       where EXISTS
          (select m.movie_id from REVIEW r
                  where r.score_pct >= 70 and r.critic_number >= 100
		    and m.movie_id = r.movie_id
		  );

select m.title from MOVIE m
       where 0 < (
              select count(*) from REVIEW r
	     	 where r.score_pct >= 70 and r.critic_number >= 100
		   and m.movie_id = r.movie_id
	  );

-- 5*/

select title, release_date from movie order by extract(YEAR from release_date), title;

-- 6*/

select title, gender, running_time
from movie
where gender like '%action%' and
      running_time > ( select max(running_time) from movie where gender='epic space opera');

select title, gender, running_time
from movie
where gender like '%action%' and
      running_time > ALL ( select running_time from movie where gender='epic space opera');

-- 7*/

select title, gender, running_time
from movie
where gender like '%action%' and
      running_time > ( select min(running_time) from movie where gender='epic space opera');

select title, gender, running_time
from movie
where gender like '%action%' and
      running_time > ANY ( select running_time from movie where gender='epic space opera');

-- 8*/

select * from movie where
  movie_id not in (select movie_id from play where
                  cine_id in (select cine_id from cinema
		                 where company='MK2')
				 );

select * from movie m where 
          not exists (select * from play p where
                  p.cine_id=m.movie_id and
                  exists (select * from cinema c
		                 where c.cine_id=p.cine_id and
				    c.company='MK2')
				 );

select * from movie m 
         where not exists (
                select m.movie_id from play p, cinema c 
  	                          where p.movie_id=m.movie_id and
			                c.cine_id=p.cine_id and
			                c.company='MK2'
				 );

select * from movie m 
         where m.movie_id not in (
                select p.movie_id from play p, cinema c 
  	                          where c.cine_id=p.cine_id and
			                c.company='MK2'
				 );

--3.1 Plan d execution:

alter session set OPTIMIZER_MODE=ALL_ROWS ;



-- 3.2 Utilisation d index

alter session set OPTIMIZER_MODE=ALL_ROWS ;
set autotrace traceonly 

--desc v$object_usage

-- activer le monotoring
-- Alter index idxtitlemovie monitoring usage ;

-- desactiver le mode monitoring

--Alter index idxtitlemovie monotoring usage ;

 CREATE INDEX IDXLASTNAMEPERSON ON PERSON(LASTNAME)
 Alter index IDXLASTNAMEPERSON monitoring usage ;

SELECT /*+ NO_INDEX(PERSON,IDXLASTNAMEPERSON)*/ LASTNAME  FROM PERSON WHERE LASTNAME LIKE 'L%' ;
SELECT * FROM PERSON WHERE LASTNAME LIKE 'L%' ;

CREATE INDEX IDXTITLEMOVIE ON MOVIE(TITLE) ; 
CREATE INDEX IDXGENDERMOVIE ON MOVIE(GENDER) ; 

Alter index IDXTITLEMOVIE monitoring usage ;

Alter index IDXGENDERMOVIE monitoring usage ;

--req 1
SELECT * FROM MOVIE
	WHERE GENDER LIKE 'EPIC%';

-- Sans l utilisation de index
SELECT /*+ NO_INDEX(MOVIE,IDXGENDERMOVIE)*/ * FROM MOVIE
	WHERE GENDER LIKE 'EPIC%';

--req 2 
SELECT * FROM MOVIE
	WHERE GENDER IS NULL;

SELECT /*+ NO_INDEX(MOVIE,IDXGENDERMOVIE)*/* FROM MOVIE
	WHERE GENDER IS NULL;

--4 index BITMAP

DROP INDEX IDXGENDERMOVIE ;

CREATE BITMAP INDEX BTPIDXGENDERMOVIE ON MOVIE(GENDER) ; 

SELECT * FROM MOVIE
	WHERE GENDER LIKE 'EPIC%';

-- Sans l utilisation de index
SELECT /*+ NO_INDEX(MOVIE,BTPIDXGENDERMOVIE)*/ * FROM MOVIE
	WHERE GENDER LIKE 'EPIC%';

SELECT * FROM MOVIE
	WHERE GENDER IS NULL;

-- Sans l utilisation de index
SELECT /*+ NO_INDEX(MOVIE,BTPIDXGENDERMOVIE)*/* FROM MOVIE
	WHERE GENDER IS NULL;


--5 Ajoutez  un  index  composite IDXTITLEGENDERMOVIE sur les attributs TITLE et GENDER de la table MOVIE

DROP INDEX BTPIDXGENDERMOVIE ;

CREATE INDEX IDXGENDERMOVIE ON MOVIE(GENDER) ;
Alter index IDXGENDERMOVIE monitoring usage ;

CREATE INDEX IDXTITLEGENDERMOVIE ON MOVIE(TITLE,GENDER) ; 
Alter index IDXTITLEGENDERMOVIE monitoring usage ;

-- apres introduction de l index 
SELECT * FROM MOVIE
	WHERE UPPER(GENDER) LIKE 'EPIC%';

SELECT * FROM MOVIE
	WHERE GENDER LIKE 'EPIC%';

-- avant introduction de l index 

SELECT /*+ NO_INDEX(MOVIE,IDXTITLEGENDERMOVIE)*/ * FROM MOVIE
	WHERE UPPER(GENDER) LIKE 'EPIC%';

SELECT /*+ NO_INDEX(MOVIE,IDXTITLEGENDERMOVIE)*/ * FROM MOVIE
	WHERE GENDER LIKE 'EPIC%';


SELECT * FROM MOVIE
	WHERE GENDER IS NULL;

SELECT /*+ NO_INDEX(MOVIE,IDXTITLEGENDERMOVIE)*/ * FROM MOVIE
	WHERE GENDER IS NULL;

-- modifier la requete 1 afin de s ́electionner les films dont le titre com-mence parSet le genre parepic
SELECT * FROM MOVIE
	WHERE GENDER LIKE 'EPIC%' and TITLE LIKE 'S%';

SELECT /*+ NO_INDEX(MOVIE,IDXTITLEGENDERMOVIE)*/* FROM MOVIE
	WHERE GENDER LIKE 'EPIC%' and TITLE LIKE 'S%';

-- 4 Utilisation des indicatuers
-- 4.1 Remplissage de la table MOVIE

CREATE SEQUENCE movie_seq INCREMENT BY 1 START WITH 40;

CREATE OR REPLACE PROCEDURE insertMovies(nbMovies IN NUMBER) IS
	id NUMBER := 0;
	created_movies NUMBER := 0;
	budget NUMBER := 0;
	running_time NUMBER := 0;
	title Movie.title%type;
	gender Movie.gender%type;
	rel_dte Date;
BEGIN
        dbms_random.seed(to_char( sysdate, 'YYYYMMDD'));
	LOOP
		id := movie_seq.nextVal;
		-- dbms_output.put_line(id);
		created_movies := created_movies + 1;
		title := dbms_random.string('U', 40);
		SELECT gender INTO gender FROM movie SAMPLE(20) where rownum < 2;
		-- dbms_random.string('U', 20);
		budget := ROUND(dbms_random.value(100, 1000000000));
		running_time := ROUND(dbms_random.value(50, 250));

		insert into MOVIE values (id , title, gender, sysdate(), running_time , budget );
		EXIT WHEN created_movies = nbMovies;
		IF created_movies mod 20 = 0 THEN
			COMMIT;
		END IF;
	END LOOP;
	COMMIT;
END;
/

 CALL insertMovies(100) ;
 ANALYZE INDEX IDXTITLEMOVIE  VALIDATE  STRUCTURE ;

 select name, height, lf_blks, br_blks, pct_used, lf_rows, del_lf_rows,DISTINCT_KEYS, MOST_REPEATED_KEY from index_stats;

-- DELETE 7000
DELETE FROM MOVIE WHERE MOVIE_ID > 3000 ;

SET TIMING ON 
drop index IDXGENDERMOVIE;
drop index IDXTITLEGENDERMOVIE;
drop index IDXTITLEMOVIE;
alter table movie modify (movie_id number(15));	
--CALL  insertMovies (1000000);

--3 
select count(title) from movie where gender like 'epic%';
select count(title) from movie where title like 'S%'and gender like 'epic%';

-- 4

create index IDXTITLEMOVIE on movie (TITLE);
Alter  index IDXTITLEMOVIE monitoring usage;
create index IDXGENDERMOVIE on movie (GENDER);
Alter  index IDXGENDERMOVIE monitoring usage;
create index IDXTITLEGENDERMOVIE on movie (TITLE,Gender);
alter index IDXTITLEGENDERMOVIE monitoring usage;
--5 
select count(title) from movie where gender like 'epic%';
select count(title) from movie where title like 'S%'and gender like 'epic%';












