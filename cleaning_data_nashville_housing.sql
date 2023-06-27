-- Cleaning Data in SQL Queries --

SELECT *
FROM nashvillehousing


-- Change/Standardise Date Format --
-- Removing the timestamp on the end as it serves no purpose 
-- Currently in date-time format. We will convert it to just date

SELECT SaleDate, CONVERT (Date, SaleDate)
FROM nashvillehousing

UPDATE nashvillehousing
SET SaleDate = CONVERT (Date, SaleDate) -- This did not work for some reason --

ALTER TABLE nashvillehousing
ADD SaleDateConverted Date;

UPDATE nashvillehousing
SET SaleDateConverted = CONVERT (Date, SaleDate)

SELECT SaleDateConverted
FROM nashvillehousing


-- Populate Property Address Data --

SELECT *
FROM nashvillehousing
--WHERE PropertyAddress is null
ORDER BY ParcelID --it appears that duplicate ParcelID fields have the same address


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM nashvillehousing a
JOIN nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL -- we can see there is a property address in table b, but it is not populating table a


-- add an IS NULL function
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashvillehousing a
JOIN nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

-- Update Column

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashvillehousing a
JOIN nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

-- Now if we run the previous code there should be no results appearing as there should be no NULLs



-- Breaking out Address into Invidual Columns (Address, City, State) --
-- Using Substring & Character Index

SELECT PropertyAddress
FROM nashvillehousing
-- There is one comma separating the address from the city name


SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX (',', PropertyAddress)) as Address
FROM nashvillehousing
-- This includes the comma in the output. We do not want that.

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX (',', PropertyAddress)) as Address,
CHARINDEX (',', PropertyAddress)
FROM nashvillehousing
-- Shows at which position the comma is.

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX (',', PropertyAddress) -1) as Address
FROM nashvillehousing
-- adding the '-1' removes the comma.

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX (',', PropertyAddress) -1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX (',', PropertyAddress) +1, LEN(PropertyAddress)) as Address
FROM nashvillehousing
-- Selecting just the City name


--Now we need to create columns
ALTER TABLE nashvillehousing
	ADD PropertySplitAddress Nvarchar (255);
UPDATE nashvillehousing
	SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX (',', PropertyAddress) -1)


ALTER TABLE nashvillehousing
	ADD PropertySplitCity Nvarchar (255);
UPDATE nashvillehousing
	SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX (',', PropertyAddress) +1, LEN(PropertyAddress))


SELECT *
From nashvillehousing
-- the two new columns have been added at the end of the table
-- the address data is now more usable



-- We can do a similar process for the Owner Address
-- Using PARSENAME; only useful with periods
-- Easier to use than SUBSTRING

SELECT OwnerAddress
FROM nashvillehousing


SELECT
PARSENAME(OwnerAddress,1) -- does nothing as we have commas and not periods
FROM nashvillehousing


SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) -- Replace the commas with periods
, PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)
FROM nashvillehousing
--everything has been separated for us but done backwards

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) 
, PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)
FROM nashvillehousing
-- switched around


--Now we need to create columns
ALTER TABLE nashvillehousing
	ADD OwnerSplitAddress Nvarchar (255);
UPDATE nashvillehousing
	SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) 


ALTER TABLE nashvillehousing
	ADD OwnerSplitCity Nvarchar (255);
UPDATE nashvillehousing
	SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)


ALTER TABLE nashvillehousing
	ADD OwnerSplitState Nvarchar (255);
UPDATE nashvillehousing
	SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)


SELECT *
From nashvillehousing
-- the three new columns have been added at the end of the table
-- the address data is now more usable



-- Change Y and N to Yes and No in "Sold as Vacant" field --

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM nashvillehousing
GROUP BY SoldAsVacant
ORDER BY 2
-- inconsistent entries, there is 'Y', 'N', 'Yes' and 'No'


-- Use CASE statement to change all entries to be consistent
SELECT SoldAsVacant
,  CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM nashvillehousing

UPDATE nashvillehousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END





-- Remove Duplicates --
-- Using CTE & PARTITION BY --

-- First do PARTITION BY clause --
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference
	ORDER BY
		UniqueID
		) row_num

FROM nashvillehousing
ORDER BY ParcelID


-- create CTE --

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference
	ORDER BY
		UniqueID
		) row_num
FROM nashvillehousing
)
SELECT *
FROM RowNumCTE
WHERE row_num >1
ORDER BY PropertyAddress
-- Returns all the duplicate entries --

-- change the SELECT statement to DELETE to remove duplicates--

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference
	ORDER BY
		UniqueID
		) row_num
FROM nashvillehousing
)
DELETE 
FROM RowNumCTE
WHERE row_num >1
-- Now if we re-run the previous code, there should be no duplicates --


-- Delete Unused Columns -- 

SELECT *
FROM nashvillehousing

ALTER TABLE nashvillehousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE nashvillehousing
DROP COLUMN SaleDate