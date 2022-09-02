-- Upload to MYSQL

TRUNCATE TABLE housing_project.housing;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/housing.csv' 
INTO TABLE housing_project.housing
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;

SELECT * FROM housing_project.housing;

-- Populate Property Address data

SELECT *
FROM housing_project.housing
WHERE PropertyAddress is null;

-- Same ParcelID does match same property address, hence can use same address if id match

SELECT a.ParcelID
	,a.PropertyAddress
    ,b.ParcelID
    ,b.PropertyAddress
    ,IFNULL (a.PropertyAddress,b.PropertyAddress)
FROM housing_project.housing AS a
JOIN housing_project.housing AS b
	ON a.ParcelID=b.ParcelID
    AND a.UniqueID<>b.UniqueID
WHERE a.PropertyAddress is null;

SET SQL_SAFE_UPDATES = 0;
UPDATE housing_project.housing AS t1
JOIN housing_project.housing AS t2
	ON t1.ParcelID=t2.ParcelID
    AND t1.UniqueID<>t2.UniqueID
SET t1.PropertyAddress=IFNULL (t1.PropertyAddress,t2.PropertyAddress)
WHERE t1.PropertyAddress is null;



-- Breaking out Address into Individual Columns (Address,City.State)

SELECT PropertyAddress
FROM housing_project.housing;
-- WHERE PropertyAddress is null;

SELECT 
	SUBSTRING(PropertyAddress,1,locate(',', PropertyAddress)-1) AS split_address
    ,SUBSTRING(PropertyAddress,locate(',', PropertyAddress)+1,length(PropertyAddress)) AS split_address_city
FROM housing_project.housing;

ALTER TABLE housing_project.housing
ADD split_address nvarchar(255);

UPDATE housing_project.housing
SET split_address=SUBSTRING(PropertyAddress,1,locate(',', PropertyAddress)-1);

ALTER TABLE housing_project.housing
ADD split_address_city varchar(255);

UPDATE housing_project.housing
SET split_address_city=SUBSTRING(PropertyAddress,locate(',', PropertyAddress)+1,length(PropertyAddress));



-- Splitting Owner address into collumns

SELECT 
	SUBSTRING_INDEX(OwnerAddress,',',1) AS owner_address
	,SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',2),',',-1) AS owner_city
    ,SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',3),',',-1) AS owner_state
FROM housing_project.housing;

ALTER TABLE housing_project.housing
ADD owner_address nvarchar(255);

UPDATE housing_project.housing
SET owner_address=SUBSTRING_INDEX(OwnerAddress,',',1);

ALTER TABLE housing_project.housing
ADD owner_city nvarchar(255);

UPDATE housing_project.housing
SET owner_city=SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',2),',',-1);

ALTER TABLE housing_project.housing
ADD owner_state nvarchar(255);

UPDATE housing_project.housing
SET owner_state=SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',3),',',-1);



-- Change Y and N to Yes and No in SoldAsVacant field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM housing_project.housing
GROUP BY SoldAsVacant
ORDER BY 2;

SET SQL_SAFE_UPDATES = 0;
UPDATE housing_project.housing
SET SoldAsVacant=
	CASE WHEN SoldAsVacant='Y' THEN 'Yes'
		WHEN SoldAsVacant='N' THEN 'No'
        ELSE SoldAsVacant
        END;


-- Remove Duplicates (not taking UniqueID into account for excercise purpose, but based on ParcceID+SaleDate+LegalReference)

ALTER TABLE housing_project.housing
  ADD id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY FIRST;

WITH RowNumCTE AS (
SELECT *
	,ROW_NUMBER() OVER(
    PARTITION BY ParcelID
				,SaleDate
                ,LegalReference
                ORDER BY 
					UniqueID
                    ) row_num  -- gives row number if columns selected match
FROM housing_project.housing
)
DELETE t
FROM RowNumCTE
JOIN  housing_project.housing t USING(id)
WHERE row_num>1;

-- Delete Unused Columns 

ALTER TABLE housing_project.housing
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress;

-- SelePrice formating

UPDATE housing_project.housing
SET SalePrice = REPLACE(SalePrice, '$', '');
UPDATE housing_project.housing
SET SalePrice = REPLACE(SalePrice, ',', '');

