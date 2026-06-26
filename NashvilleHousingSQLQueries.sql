-- copied and altered with permission from AlexTheAnalyst

-- check data
SELECT
	*
FROM
	PortfolioProject..NashvilleHousing


-- change sale date format
SELECT
	SaleDateConverted
	--CONVERT(date, SaleDate)
FROM
	PortfolioProject..NashvilleHousing

--UPDATE NashvilleHousing
--SET SaleDate = CONVERT(date, SaleDate)
-- this didn't end up working

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)



-- populate property address data
-- use duplicated parcel IDs to copy the property address
SELECT
	*
FROM
	PortfolioProject..NashvilleHousing
--WHERE
--	PropertyAddress IS NULL
ORDER BY
	ParcelID


SELECT
	A.ParcelID,
	A.PropertyAddress,
	B.ParcelID,
	B.PropertyAddress,
	ISNULL(A.PropertyAddress, B.PropertyAddress) --if A.PropertyAddress is null, replace it with B.PropertyAddress as a new column
FROM
	PortfolioProject..NashvilleHousing A
JOIN
	PortfolioProject..NashvilleHousing B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE
	A.PropertyAddress IS NULL

UPDATE A -- use the table's alias, not the actual table name
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM
	PortfolioProject..NashvilleHousing A
JOIN
	PortfolioProject..NashvilleHousing B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE
	A.PropertyAddress IS NULL

-- run the previous query again to check that it worked



-- break the property address into individual columns (Address, City)
SELECT
	PropertyAddress
FROM
	PortfolioProject..NashvilleHousing
--WHERE
--	PropertyAddress IS NULL
--ORDER BY
--	ParcelID

SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address, -- column, start position, delimiter, go before the delimiter
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City -- go to the next part after the delimiter
FROM
	PortfolioProject..NashvilleHousing

	--create two new columns for address and city
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);
UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))




-- break the owner address into individual columns (Address, City, State)
SELECT
	OwnerAddress
FROM
	PortfolioProject..NashvilleHousing

SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'),3), -- replaces the comma before the state name with a period
	PARSENAME(REPLACE(OwnerAddress, ',', '.'),2),	--because PARSENAME separates strings by periods
	PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)	--works from the end of the string
FROM
	PortfolioProject..NashvilleHousing

	--add these columns to the table

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)


ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)


ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)




-- change Y to Yes and N to No in SoldAsVacant
SELECT
	DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM
	PortfolioProject..NashvilleHousing
GROUP BY
	SoldAsVacant
ORDER BY
	2


SELECT
	SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM
	PortfolioProject..NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END



-- remove duplicates as practice
-- make a CTE
WITH row_numCTE AS (
	SELECT
		*,
		ROW_NUMBER() OVER(
		PARTITION BY ParcelID, 
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
					ORDER BY 
						UniqueID
						) row_num
	FROM
		PortfolioProject..NashvilleHousing
)

SELECT
	*
FROM
	row_numCTE
WHERE
	row_num > 1
ORDER BY 
	PropertyAddress




-- delete unused columns (never do to raw data)
SELECT
	*
FROM
	PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN SaleDate,
			OwnerAddress,
			TaxDistrict,
			PropertyAddress