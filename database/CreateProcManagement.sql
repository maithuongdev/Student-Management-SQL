-- SQL script for creating stored procedures in the QLSVNhom system
USE QLSVNhom;
GO

-- 1. Employee authentication
CREATE OR ALTER PROCEDURE SP_LOGIN_PUBLIC_ENCRYPT_NHANVIEN
    @TENDN NVARCHAR(50),
    @MK VARBINARY(MAX) -- SHA1-hashed password received from the client
AS
BEGIN
    SET NOCOUNT ON;

    -- Verify whether the employee exists
    IF NOT EXISTS (SELECT 1 FROM NHANVIEN WHERE TENDN = @TENDN AND MATKHAU = @MK)
    BEGIN
        SELECT -1 AS Result, N'Invalid username or password.' AS Message;
        RETURN;
    END;

    -- Return employee information upon successful login
    SELECT 1 AS Result, MANV, HOTEN
    FROM NHANVIEN
    WHERE TENDN = @TENDN;
END;
GO

-- 2. Insert a new employee
CREATE OR ALTER PROCEDURE SP_INS_PUBLIC_ENCRYPT_NHANVIEN
    @MANV NVARCHAR(10),
    @HOTEN NVARCHAR(100),
    @EMAIL NVARCHAR(100),
    @LUONG VARBINARY(MAX),
    @TENDN NVARCHAR(50),
    @MK VARBINARY(MAX), -- SHA1-hashed password received from the client
    @PUB NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- Check for duplicate employee ID
    IF EXISTS (SELECT 1 FROM NHANVIEN WHERE MANV = @MANV)
    BEGIN
        SELECT -1 AS Result, N'Employee ID already exists.' AS Message;
        RETURN;
    END

    -- Check for duplicate username
    IF EXISTS (SELECT 1 FROM NHANVIEN WHERE TENDN = @TENDN)
    BEGIN
        SELECT -1 AS Result, N'Username already exists.' AS Message;
        RETURN;
    END

    -- Insert employee information
    INSERT INTO NHANVIEN (MANV, HOTEN, EMAIL, LUONG, TENDN, MATKHAU, PUBKEY)
    VALUES (@MANV, @HOTEN, @EMAIL, @LUONG, @TENDN, @MK, @PUB);

    -- Return success
    SELECT 1 AS Result, N'Employee added successfully.' AS Message;
END;
GO

-- 3. Update employee information
CREATE OR ALTER PROCEDURE SP_UPDATE_PUBLIC_ENCRYPT_NHANVIEN
    @MANV NVARCHAR(10),
    @HOTEN NVARCHAR(100),
    @EMAIL NVARCHAR(100),
    @LUONG VARBINARY(MAX),
    @TENDN NVARCHAR(50),
    @MK VARBINARY(MAX) -- SHA1-hashed password received from the client
AS
BEGIN
    SET NOCOUNT ON;

    -- Verify that the employee exists
    IF NOT EXISTS (SELECT 1 FROM NHANVIEN WHERE MANV = @MANV)
    BEGIN
        SELECT -1 AS Result, N'Employee does not exist.' AS Message;
        RETURN;
    END

    -- Ensure the username is not assigned to another employee
    IF EXISTS (SELECT 1 FROM NHANVIEN WHERE TENDN = @TENDN AND MANV <> @MANV)
    BEGIN
        SELECT -2 AS Result, N'Username is already used by another employee.' AS Message;
        RETURN;
    END

    -- Update employee information
    UPDATE NHANVIEN
    SET HOTEN = @HOTEN,
        EMAIL = @EMAIL,
        LUONG = @LUONG,
        TENDN = @TENDN,
        MATKHAU = @MK
    WHERE MANV = @MANV;

    -- Return success
    SELECT 1 AS Result, N'Employee information updated successfully.' AS Message;
END;
GO

-- 4. Retrieve all employees
CREATE OR ALTER PROCEDURE SP_SEL_NHANVIEN
AS
BEGIN
    SET NOCOUNT ON;

    -- Retrieve the employee list
    SELECT MANV, HOTEN, EMAIL, LUONG
    FROM NHANVIEN;
END;
GO

-- 5. Create a new class
CREATE OR ALTER PROCEDURE SP_INS_PUBLIC_ENCRYPT_LOP
    @MALOP NVARCHAR(20),
    @TENLOP NVARCHAR(100),
    @MANV NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- Check for duplicate class ID
    IF EXISTS (SELECT 1 FROM LOP WHERE MALOP = @MALOP)
    BEGIN
        SELECT -2 AS Result;
        RETURN;
    END

    -- Insert the new class
    INSERT INTO LOP (MALOP, TENLOP, MANV)
    VALUES (@MALOP, @TENLOP, @MANV);

    -- Return success
    SELECT 1 AS Result;
    RETURN;
END;
GO

-- 6. Delete a class
CREATE OR ALTER PROCEDURE SP_DEL_PUBLIC_ENCRYPT_LOP
    @MANV NVARCHAR(20),
    @MALOP NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- Verify that the class exists and belongs to the employee
    IF NOT EXISTS (SELECT 1 FROM LOP WHERE MALOP = @MALOP AND MANV = @MANV)
    BEGIN
        SELECT -1 AS Result;
        RETURN;
    END

    -- Delete all students assigned to the class
    DELETE FROM SINHVIEN
    WHERE MALOP = @MALOP;

    -- Delete the class
    DELETE FROM LOP
    WHERE MALOP = @MALOP;

    SELECT 1 AS Result;
END;
GO

-- 7. Retrieve students from classes managed by the employee
CREATE OR ALTER PROCEDURE SP_SEL_PUBLIC_ENCRYPT_SINHVIEN_LOP
    @MANV NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- Retrieve only students from classes managed by the specified employee
    SELECT SV.MASV,
           SV.HOTEN,
           SV.NGAYSINH,
           SV.DIACHI,
           L.TENLOP
    FROM SINHVIEN SV
    JOIN LOP L ON SV.MALOP = L.MALOP
    WHERE L.MANV = @MANV;
END;
GO

-- 8. Update student information
CREATE OR ALTER PROCEDURE SP_UPDATE_PUBLIC_ENCRYPT_SINHVIEN
    @MANV NVARCHAR(10),
    @MASV NVARCHAR(20),
    @HOTEN NVARCHAR(100),
    @NGAYSINH DATETIME,
    @DIACHI NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    -- Verify access permission
    IF NOT EXISTS (
        SELECT 1
        FROM SINHVIEN SV
        JOIN LOP L ON SV.MALOP = L.MALOP
        WHERE SV.MASV = @MASV
          AND L.MANV = @MANV
    )
    BEGIN
        SELECT -1 AS Result;
        RETURN;
    END

    -- Update student information
    UPDATE SINHVIEN
    SET HOTEN = @HOTEN,
        NGAYSINH = @NGAYSINH,
        DIACHI = @DIACHI
    WHERE MASV = @MASV;

    SELECT 1 AS Result;
END;
GO

-- 9. Insert an encrypted student exam score
CREATE OR ALTER PROCEDURE SP_INS_PUBLIC_ENCRYPT_BANGDIEM
    @MASV NVARCHAR(20),
    @MAHP NVARCHAR(20),
    @DIEMTHI VARBINARY(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- Verify that the student exists
    IF NOT EXISTS (SELECT 1 FROM SINHVIEN WHERE MASV = @MASV)
    BEGIN
        SELECT -1 AS Result;
        RETURN;
    END

    -- Verify that the course exists
    IF NOT EXISTS (SELECT 1 FROM HOCPHAN WHERE MAHP = @MAHP)
    BEGIN
        SELECT -1 AS Result;
        RETURN;
    END

    -- Check whether the score already exists
    IF EXISTS (SELECT 1 FROM BANGDIEM WHERE MASV = @MASV AND MAHP = @MAHP)
    BEGIN
        SELECT -2 AS Result;
        RETURN;
    END

    -- Insert the encrypted exam score
    INSERT INTO BANGDIEM (MASV, MAHP, DIEMTHI)
    VALUES (@MASV, @MAHP, @DIEMTHI);

    -- Return success
    SELECT 1 AS Result;
END;
GO

-- 10. Retrieve an encrypted exam score
CREATE OR ALTER PROCEDURE SP_SEL_PUBLIC_ENCRYPT_BANGDIEM
    @MASV VARCHAR(20),
    @MAHP VARCHAR(20),
    @MANV VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- Return the encrypted exam score without decryption
    IF EXISTS (SELECT 1 FROM BANGDIEM WHERE MASV = @MASV AND MAHP = @MAHP)
    BEGIN
        SELECT MASV,
               MAHP,
               DIEMTHI
        FROM BANGDIEM
        WHERE MASV = @MASV
          AND MAHP = @MAHP;
    END
    ELSE
    BEGIN
        -- Return NULL values if no record is found
        SELECT NULL AS MASV,
               NULL AS MAHP,
               NULL AS DIEMTHI;
    END
END;
GO

EXEC SP_SEL_PUBLIC_ENCRYPT_BANGDIEM 'SV01', 'BMCSDL', 'SVG';
GO

DELETE FROM SINHVIEN
WHERE MASV = 'SV01';