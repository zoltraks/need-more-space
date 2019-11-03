
--
-- Create table structure
--

CREATE TABLE IF NOT EXISTS `contact`
(
  `Id` INT NOT NULL AUTO_INCREMENT COMMENT 'Record key' ,

  `Title` VARCHAR(50) NULL COMMENT 'Contact title' ,
  `FirstName` VARCHAR(50) NULL COMMENT 'First name' ,
  `SecondName` VARCHAR(50) NULL COMMENT 'Second name' ,
  `LastName` VARCHAR(50) NULL COMMENT 'Last name' ,

  PRIMARY KEY (`Id`)
)
ENGINE = InnoDB
;

CREATE TABLE IF NOT EXISTS `messenger_account`
(
  `Id` INT NOT NULL AUTO_INCREMENT COMMENT 'Record key' ,

  `ContactId` INT NOT NULL COMMENT 'Record key' ,
  `MessengerServiceId` INT NULL COMMENT 'Service key' ,
  `AccountName` VARCHAR(100) NULL COMMENT 'Account name' ,
  `CustomServiceName` VARCHAR(100) NULL COMMENT 'Custom messenger' ,
  `DisplayOrder` SMALLINT NOT NULL DEFAULT 0 COMMENT 'Account name' ,

  PRIMARY KEY (`Id`)
)
ENGINE = InnoDB
;

CREATE TABLE IF NOT EXISTS `messenger_service`
(
  `Id` INT NOT NULL AUTO_INCREMENT COMMENT 'Record key' ,

  `ServiceName` VARCHAR(20) NOT NULL COMMENT 'Messenger service' ,
  `AccountFormat` VARCHAR(20) NULL COMMENT 'Account format' ,
  `DisplayOrder` SMALLINT NOT NULL DEFAULT 0 COMMENT 'Account name' ,

  PRIMARY KEY (`Id`)
)
ENGINE = InnoDB
;
