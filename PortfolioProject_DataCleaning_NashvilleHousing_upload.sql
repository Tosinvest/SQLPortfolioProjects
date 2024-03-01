-- DATA CLEANING QUERIES --

SELECT *
FROM portfolioproject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- STANDARDIZE DATE FORMAT

SELECT saledate, CONVERT(Date,SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing 
ALTER COLUMN SaleDate DATE


-- POPULATING PROPERTY ADDRESS

SELECT *
FROM portfolioproject.dbo.NashvilleHousing
--WHERE propertyaddress IS NULL
ORDER BY ParcelID

-- From the data, if the parcelID is the same, the address will be the same

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL (a.PropertyAddress,b.PropertyAddress)
FROM portfolioproject.dbo.NashvilleHousing a
	JOIN portfolioproject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL
ORDER BY a.ParcelID

UPDATE a
SET PropertyAddress = ISNULL (a.PropertyAddress,b.PropertyAddress)
FROM portfolioproject.dbo.NashvilleHousing a
	JOIN portfolioproject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL


--- BREAKING OUT ADDRESS INTO INDIVIDIAL COLUMNS (ADDRESS, CITY, STATE)

SELECT PropertyAddress, OwnerAddress
FROM portfolioproject.dbo.NashvilleHousing

/* Updating the property Address */

SELECT PropertyAddress, 
SUBSTRING (PropertyAddress, 1, CHARINDEX (',', PropertyAddress) -1) NewPropertyAddress,
SUBSTRING (PropertyAddress, CHARINDEX (',', PropertyAddress) +1, LEN (PropertyAddress)) PropertyCity
FROM portfolioproject.dbo.NashvilleHousing

ALTER TABLE portfolioproject.dbo.NashvilleHousing
ADD NewPropertyAddress Nvarchar (255);

UPDATE portfolioproject.dbo.NashvilleHousing
SET NewPropertyAddress = SUBSTRING (PropertyAddress, 1, CHARINDEX (',', PropertyAddress) -1)

ALTER TABLE portfolioproject.dbo.NashvilleHousing
ADD PropertyCity Nvarchar (255);

UPDATE portfolioproject.dbo.NashvilleHousing
SET PropertyCity = SUBSTRING (PropertyAddress, CHARINDEX (',', PropertyAddress) +1, LEN (PropertyAddress))

SELECT PropertyAddress, NewPropertyAddress, PropertyCity
FROM portfolioproject.dbo.NashvilleHousing


/* Updating the Owner's Address */

SELECT OwnerAddress, 
PARSENAME (REPLACE (OwnerAddress, ',', '.'), 3) NewOwnerAddress,
PARSENAME (REPLACE (OwnerAddress, ',', '.'), 2) OwnerCity,
PARSENAME (REPLACE (OwnerAddress, ',', '.'), 1) OwnerState
FROM portfolioproject.dbo.NashvilleHousing
WHERE OwnerAddress IS NOT NULL


ALTER TABLE portfolioproject.dbo.NashvilleHousing
ADD NewOwnerAddress Nvarchar (255);

UPDATE portfolioproject.dbo.NashvilleHousing
SET NewOwnerAddress = PARSENAME (REPLACE (OwnerAddress, ',', '.'), 3)

ALTER TABLE portfolioproject.dbo.NashvilleHousing
ADD OwnerCity Nvarchar (255);

UPDATE portfolioproject.dbo.NashvilleHousing
SET OwnerCity = PARSENAME (REPLACE (OwnerAddress, ',', '.'), 2)

ALTER TABLE portfolioproject.dbo.NashvilleHousing
ADD OwnerState Nvarchar (255);

UPDATE portfolioproject.dbo.NashvilleHousing
SET OwnerState = PARSENAME (REPLACE (OwnerAddress, ',', '.'), 1)



-----------------------------------------------------------------------------------------------------------
/* Change Y and N to Yes and No in "Sold as Vacant" field */

-- This was used to count the number of times that Y, N, Yes and No was used in the data

SELECT DISTINCT (SoldAsVacant), COUNT (SoldAsVacant)
FROM portfolioproject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant
,	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END
FROM portfolioproject.dbo.NashvilleHousing

UPDATE portfolioproject.dbo.NashvilleHousing
SET SoldAsVacant = CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END


------------------------------------------------------------------------------------------------------------------------------
/* Removing Duplicates*/

WITH RowNumCTE AS (
SELECT *, 
	ROW_NUMBER () OVER (
		PARTITION BY ParcelID, 
					PropertyAddress,
					SaleDate,
					SalePrice,
					LegalReference
					ORDER BY
						UniqueID
					) RowNum
FROM portfolioproject.dbo.NashvilleHousing
)

SELECT *
FROM RowNumCTE
WHERE RowNum > 1


-- Then, to delete the duplicates, we'll use DELETE function in the CTE instead of the SELECT function

WITH RowNumCTE AS (
SELECT *, 
	ROW_NUMBER () OVER (
		PARTITION BY ParcelID, 
					PropertyAddress,
					SaleDate,
					SalePrice,
					LegalReference
					ORDER BY
						UniqueID
					) RowNum
FROM portfolioproject.dbo.NashvilleHousing
)

DELETE 
FROM RowNumCTE
WHERE RowNum > 1


--------------------------------------------------------------------------------------------------------------------

/* Deleting Unused Columns */

ALTER TABLE portfolioproject.dbo.NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress


