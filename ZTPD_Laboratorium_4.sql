-- Przetwarzanie danych przestrzennych
-- Ćwiczenie 1.
-- A.
INSERT INTO USER_SDO_GEOM_METADATA (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID)
VALUES (
    'FIGURY', 'KSZTALT',
    SDO_DIM_ARRAY(
        SDO_DIM_ELEMENT('X', 0, 10, 0.01),
        SDO_DIM_ELEMENT('Y', 0, 10, 0.01)
    ), NULL
);
COMMIT;

-- B. 
SELECT SDO_TUNE.ESTIMATE_RTREE_INDEX_SIZE(3000000, 8192, 10, 2, 0) AS EST_SIZE 
FROM DUAL;

-- C.
CREATE INDEX figury_idx ON figury(ksztalt) INDEXTYPE IS MDSYS.SPATIAL_INDEX;

-- D. 
SELECT id FROM FIGURY
WHERE SDO_FILTER(ksztalt, SDO_GEOMETRY(2001, NULL, SDO_POINT_TYPE(3,3,NULL), NULL, NULL)) = 'TRUE';

-- E.
SELECT id FROM FIGURY 
WHERE SDO_RELATE(ksztalt, SDO_GEOMETRY(2001, NULL, SDO_POINT_TYPE(3,3,NULL), NULL, NULL), 'mask=ANYINTERACT') = 'TRUE';

-- Ćwiczenie 2.
-- A.
SELECT c.city_name AS MIASTO, SDO_NN_DISTANCE(1) AS ODL
FROM major_cities c
WHERE SDO_NN(c.geom, 
    ( SELECT geom FROM major_cities WHERE city_name = 'Warsaw'), 
    'sdo_num_res=10 unit=km', 1) = 'TRUE'
AND c.city_name <> 'Warsaw';

-- B.
SELECT city_name AS MIASTO
FROM major_cities
WHERE SDO_WITHIN_DISTANCE(
    geom, 
    (SELECT geom FROM major_cities WHERE city_name = 'Warsaw'), 
    'distance=100 unit=km'
) = 'TRUE' AND city_name <> 'Warsaw';

-- C.
SELECT b.cntry_name AS KRAJ, c.city_name AS MIASTO
FROM major_cities c, country_boundaries b
WHERE b.cntry_name = 'Slovakia'
AND SDO_RELATE(c.geom, b.geom, 'mask=INSIDE') = 'TRUE';

-- D.
SELECT b2.cntry_name AS PANSTWO, SDO_GEOM.SDO_DISTANCE(b1.geom, b2.geom, 1, 'unit=km') AS ODL
FROM country_boundaries b1, country_boundaries b2
WHERE b1.cntry_name = 'Poland'
AND b2.cntry_name <> 'Poland'
AND b2.cntry_name NOT IN (
    SELECT b3.cntry_name 
    FROM country_boundaries b3
    WHERE SDO_RELATE(b3.geom, b1.geom, 'mask=TOUCH') = 'TRUE'
);

-- Ćwiczenie 3.
--A.
SELECT b2.cntry_name, SDO_GEOM.SDO_LENGTH(SDO_GEOM.SDO_INTERSECTION(b1.geom, b2.geom, 1), 1, 'unit=km') AS ODLEGLOSC
FROM country_boundaries b1, country_boundaries b2
WHERE b1.cntry_name = 'Poland' AND SDO_RELATE(b2.geom, b1.geom, 'mask=TOUCH') = 'TRUE';

-- B.
SELECT cntry_name
FROM (
    SELECT cntry_name, SDO_GEOM.SDO_AREA(geom, 1, 'unit=SQ_KM') AS area
    FROM country_boundaries
    ORDER BY area DESC
) WHERE ROWNUM = 1;

-- C.
SELECT SDO_GEOM.SDO_AREA(SDO_GEOM.SDO_MBR(SDO_GEOM.SDO_UNION(c1.geom, c2.geom, 1)), 1, 'unit=SQ_KM') AS SQ_KM
FROM major_cities c1, major_cities c2
WHERE c1.city_name = 'Warsaw' AND c2.city_name = 'Lodz';

-- D.
SELECT SDO_GEOM.SDO_UNION(b.geom, c.geom, 1).SDO_GTYPE AS GTYPE
FROM country_boundaries b, major_cities c
WHERE b.cntry_name = 'Poland' AND c.city_name = 'Prague';

-- E.
SELECT city_name, cntry_name
FROM (
    SELECT c.city_name, b.cntry_name, SDO_GEOM.SDO_DISTANCE(c.geom, SDO_GEOM.SDO_CENTROID(b.geom, 1), 1) AS dist
    FROM major_cities c, country_boundaries b
    WHERE SDO_RELATE(c.geom, b.geom, 'mask=INSIDE') = 'TRUE'
    ORDER BY dist ASC
)WHERE ROWNUM = 1;

-- F
SELECT r.name, SUM(SDO_GEOM.SDO_LENGTH(SDO_GEOM.SDO_INTERSECTION(r.geom, b.geom, 1), 1, 'unit=km')) AS DLUGOSC
FROM rivers r, country_boundaries b
WHERE b.cntry_name = 'Poland' 
AND SDO_RELATE(r.geom, b.geom, 'mask=ANYINTERACT') = 'TRUE'
AND r.name IS NOT NULL
GROUP BY r.name;