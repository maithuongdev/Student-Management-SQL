USE QLSVNhom
GO

-- Stored procedure for inserting new employee data into the NHANVIEN table
CREATE OR ALTER PROCEDURE SP_INS_PUBLIC_ENCRYPT_NHANVIEN
    @MANV NVARCHAR(10),
    @HOTEN NVARCHAR(100),
    @EMAIL NVARCHAR(100),
    @LUONG NVARCHAR(MAX),  -- Salary encrypted with RSA on the client side
    @TENDN NVARCHAR(50),
    @MK NVARCHAR(100),     -- Password hashed with SHA1 on the client side
    @PUB NVARCHAR(MAX)     -- Public key generated on the client side
AS
BEGIN
    -- Check for duplicate employee ID
    IF EXISTS (SELECT 1 FROM NHANVIEN WHERE MANV = @MANV)
    BEGIN
        RAISERROR(N'Employee ID already exists.', 16, 1);
        RETURN;
    END

    -- Check for duplicate username
    IF EXISTS (SELECT 1 FROM NHANVIEN WHERE TENDN = @TENDN)
    BEGIN
        RAISERROR(N'Username already exists.', 16, 1);
        RETURN;
    END

    -- Insert employee data into the NHANVIEN table
    INSERT INTO NHANVIEN (MANV, HOTEN, EMAIL, LUONG, TENDN, MATKHAU, PUBKEY)
    VALUES (
        @MANV,
        @HOTEN,
        @EMAIL,
        CONVERT(VARBINARY(MAX), @LUONG),
        @TENDN,
        CONVERT(VARBINARY(MAX), @MK),
        @PUB
    );

    PRINT N'Employee data inserted successfully.';
END;
GO

EXEC SP_INS_PUBLIC_ENCRYPT_NHANVIEN
    'NV01',
    'NGUYEN VAN A',
    'NVA@',
    'LLLLLL',
    'NVA',
    'MKMKMKMK',
    'PUBPUB';
GO

-- Stored procedure for retrieving employee information
CREATE PROCEDURE SP_SEL_PUBLIC_ENCRYPT_NHANVIEN
    @TENDN NVARCHAR(50),
    @MK NVARCHAR(100)  -- Password hashed with SHA1 on the client side
AS
BEGIN
    -- Retrieve employee information if the username and password match
    SELECT
        MANV,
        HOTEN,
        EMAIL,
        LUONG  -- Salary encrypted with RSA (not decrypted)
    FROM NHANVIEN
    WHERE TENDN = @TENDN
      AND MATKHAU = @MK;
END;
GO

EXEC SP_SEL_PUBLIC_ENCRYPT_NHANVIEN 'NVA', 'MKMKMKMK'
GO

SELECT * FROM NHANVIEN;

SELECT * FROM BANGDIEM;

SELECT * FROM LOP;

SELECT * FROM SINHVIEN;

DELETE FROM BANGDIEM
WHERE MASV = 'SV01';

EXEC sp_columns 'NHANVIEN';

EXEC sp_columns 'BANGDIEM';

DELETE FROM NHANVIEN
WHERE MANV = 'NV07';

DELETE FROM LOP
WHERE MALOP = 'L01';

DELETE FROM SINHVIEN
WHERE MASV = 'SV01';

ALTER TABLE NHANVIEN
ALTER COLUMN PUBKEY NVARCHAR(MAX);

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'BANGDIEM'
  AND COLUMN_NAME = 'DIEMTHI';