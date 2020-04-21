USE tempdb;
GO

CREATE FUNCTION dbo.EndOfPreviousMonth (@DateToTest date)
RETURNS date
AS BEGIN
  RETURN DATEADD(day, 0 - DAY(@DateToTest), @DateToTest);
END;
GO

SELECT dbo.EndOfPreviousMonth(SYSDATETIME());

SELECT dbo.EndOfPreviousMonth('2017-06-01');
GO

SELECT OBJECTPROPERTY(OBJECT_ID('dbo.EndOfPreviousMonth'),'IsDeterministic');
GO

DROP FUNCTION dbo.EndOfPreviousMonth;
GO

SELECT dbo.EndOfPreviousMonth(SYSDATETIME());

SELECT dbo.EndOfPreviousMonth('2018-03-01');
GO

DROP FUNCTION dbo.EndOfPreviousMonth;
GO
----------------------------------------------------------------------------------

USE AdventureWorks2012;
GO

CREATE FUNCTION Sales.GetLastOrdersForCustomer 
(@CustomerID int, @NumberOfOrders int)
RETURNS TABLE
AS
RETURN (SELECT TOP(@NumberOfOrders)
                              soh.SalesOrderID,
                              soh.OrderDate,
                              soh.PurchaseOrderNumber
                FROM Sales.SalesOrderHeader AS soh
                WHERE soh.CustomerID = @CustomerID
                ORDER BY soh.OrderDate DESC
               );
GO

SELECT * FROM Sales.GetLastOrdersForCustomer(17288,2);
GO

SELECT c.CustomerID,
             c.AccountNumber,
             glofc.SalesOrderID,
             glofc.OrderDate 
FROM Sales.Customer AS c
CROSS APPLY Sales.GetLastOrdersForCustomer(c.CustomerID,3) AS glofc
ORDER BY c.CustomerID,glofc.SalesOrderID;

DROP FUNCTION Sales.GetLastOrdersForCustomer;
GO
-----------------------------------------------------------------------

USE master;
GO

CREATE LOGIN TestContext 
  WITH PASSWORD = 'P@ssw0rd',
       CHECK_POLICY = OFF;
GO

USE AdventureWorks;
GO

CREATE USER TestContext FOR LOGIN TestContext;
GO

CREATE FUNCTION dbo.CheckContext()
RETURNS TABLE
AS
RETURN ( SELECT * FROM sys.user_token
       );
GO

SELECT * FROM dbo.CheckContext();
GO

ALTER FUNCTION dbo.CheckContext()
RETURNS TABLE
WITH EXECUTE AS 'TestContext'
AS
RETURN ( SELECT * FROM sys.user_token
       );
GO

DROP FUNCTION dbo.CheckContext;
GO

CREATE FUNCTION dbo.CheckContext()
RETURNS @UserTokenList TABLE (principal_id int, 
                              sid varbinary(85), 
                              type nvarchar(128), 
                              usage nvarchar(128),
                              name nvarchar(128))
WITH EXECUTE AS 'TestContext'
AS BEGIN
  INSERT @UserTokenList 
    SELECT principal_id,
           sid,
           type,
           usage,
           name 
    FROM sys.user_token;
  RETURN 
END;
GO

SELECT * FROM dbo.CheckContext();
GO

DROP FUNCTION dbo.CheckContext;
GO

DROP USER TestContext;
GO

DROP LOGIN TestContext;
GO
-------------------------------------