update 
(select MEASUREMENT_SEM, MEASUREMENT_SD, NUMBER_OF_ANIMALS
from EXPERIMENT_RECORD er, SAMPLE sa
where 
er.SAMPLE_ID = sa.SAMPLE_ID and 
 not er.MEASUREMENT_SD is null and
er.MEASUREMENT_SEM is null and
sa.NUMBER_OF_ANIMALS > 0 and
er.CURATION_STATUS = 40
) a 
set MEASUREMENT_SEM=MEASUREMENT_SD/sqrt(NUMBER_OF_ANIMALS);

update 
(select MEASUREMENT_SEM, MEASUREMENT_SD, NUMBER_OF_ANIMALS
from EXPERIMENT_RECORD er, SAMPLE sa
where 
er.SAMPLE_ID = sa.SAMPLE_ID and 
er.MEASUREMENT_SD is null and
not er.MEASUREMENT_SEM is null and
sa.NUMBER_OF_ANIMALS > 0 and
er.CURATION_STATUS = 40
) a 
set MEASUREMENT_SD=MEASUREMENT_SEM*sqrt(NUMBER_OF_ANIMALS);

Update 
(select MEASUREMENT_SEM, MEASUREMENT_SD, NUMBER_OF_ANIMALS
from EXPERIMENT_RECORD er, SAMPLE sa
where 
er.SAMPLE_ID = sa.SAMPLE_ID and 
NOT er.MEASUREMENT_SD is null and
not er.MEASUREMENT_SEM is null and
sa.NUMBER_OF_ANIMALS = 0 and
er.CURATION_STATUS = 40
) a 
set NUMBER_OF_ANIMALS=round(power(MEASUREMENT_SD / MEASUREMENT_SEM, 2));


select MEASUREMENT_SEM, MEASUREMENT_SD, NUMBER_OF_ANIMALS, MEASUREMENT_SD/sqrt(NUMBER_OF_ANIMALS) as a, round(MEASUREMENT_SD/sqrt(NUMBER_OF_ANIMALS)*
power(10,ceil(log(10,MEASUREMENT_SD/sqrt(NUMBER_OF_ANIMALS)))+4))/power(10,ceil(log(10,MEASUREMENT_SD/sqrt(NUMBER_OF_ANIMALS)))+4) as b
from EXPERIMENT_RECORD er, SAMPLE sa
where 
er.SAMPLE_ID = sa.SAMPLE_ID and 
 not er.MEASUREMENT_SD is null and
er.MEASUREMENT_SEM is null and
sa.NUMBER_OF_ANIMALS > 0 and
er.CURATION_STATUS = 40;