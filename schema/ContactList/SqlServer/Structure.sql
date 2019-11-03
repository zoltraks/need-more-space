
--
-- Create table structure
--

IF OBJECT_ID('dbo.[Contact]' , 'U') IS NULL
CREATE TABLE dbo.[Contact]
(
  [Id] INT IDENTITY(1,1) NOT NULL ,                        -- Record key

  [Title] NVARCHAR(100) NULL ,                             -- Contact title
  [FirstName] NVARCHAR(50) NULL ,                          -- First name
  [SecondName] NVARCHAR(50) NULL ,                         -- Second name
  [LastName] NVARCHAR(50) NULL ,                           -- Last name

  CONSTRAINT [PK_Contact] PRIMARY KEY CLUSTERED
  (
    [Id] ASC
  )
  WITH ( PAD_INDEX = OFF , STATISTICS_NORECOMPUTE = OFF , IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON )
)
ON [PRIMARY]
;

IF OBJECT_ID('dbo.[MessengerAccount]' , 'U') IS NULL
CREATE TABLE dbo.[MessengerAccount]
(
  [Id] INT IDENTITY(1,1) NOT NULL ,                        -- Record key

  [ContactId] INT NOT NULL ,                               -- Contact key 
  [MessengerServiceId] INT NULL ,                          -- Messenger key
  [AccountName] NVARCHAR(100) NOT NULL ,                   -- Account name
  [CustomServiceName] NVARCHAR(100) NULL ,                 -- Custom messenger
  [DisplayOrder] SMALLINT NOT NULL DEFAULT 0 ,             -- Display order

  CONSTRAINT [PK_MessengerAccount] PRIMARY KEY CLUSTERED
  (
    [Id] ASC
  )
  WITH ( PAD_INDEX = OFF , STATISTICS_NORECOMPUTE = OFF , IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON )
)
ON [PRIMARY]
;

IF OBJECT_ID('dbo.[MessengerService]' , 'U') IS NULL
CREATE TABLE dbo.[MessengerService]
(
  [Id] INT IDENTITY(1,1) NOT NULL ,                        -- Record key

  [ServiceName] NVARCHAR(20) NOT NULL ,                    -- Messenger service
  [AccountFormat] NVARCHAR(20) NULL ,                      -- Account format
  [DisplayOrder] SMALLINT NOT NULL DEFAULT 0 ,             -- Display order

  CONSTRAINT [PK_MessengerService] PRIMARY KEY CLUSTERED
  (
    [Id] ASC
  )
  WITH ( PAD_INDEX = OFF , STATISTICS_NORECOMPUTE = OFF , IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON )
)
ON [PRIMARY]
;
