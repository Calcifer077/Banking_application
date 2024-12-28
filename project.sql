create database banking_transactions_project

use banking_transactions_project

CREATE TABLE account_opening_form (
    id INT PRIMARY KEY IDENTITY(1000,1),
    [date] DATE DEFAULT GETDATE(),
    Account_type VARCHAR(20) DEFAULT 'saving',
    Account_HolderName VARCHAR(50),
    DOB DATE,
    AadharNumber VARCHAR(12) UNIQUE NOT NULL,
    MobileNumber VARCHAR(15),
    Account_opening_balance DECIMAL(10,2) CHECK (Account_opening_balance >= 1000),
    FullAddress VARCHAR(100),
    KYC_Status VARCHAR(20) DEFAULT 'pending' CHECK (KYC_Status IN ('approved', 'pending', 'rejected'))
);


CREATE TABLE bank (
    AccountNumber BIGINT PRIMARY KEY IDENTITY(123456789,1),
    AccountType VARCHAR(20),
    AccountOpeningDate DATE DEFAULT GETDATE(),
    CurrentBalance DECIMAL(10,2),
    initialId INT,
);

CREATE TABLE account_holder_details (
    AccountNumber BIGINT PRIMARY KEY,
    Account_HolderName VARCHAR(50),
    DOB DATE,
    AadharNumber VARCHAR(12),
    MobileNumber VARCHAR(15),
	FullAddress VARCHAR(50),
);

CREATE TABLE transaction_details (
    TransactionID INT PRIMARY KEY IDENTITY(1,1),
    AccountNumber BIGINT,
    Payment_Type VARCHAR(20) check(Payment_Type in('credit', 'debit')),
    Transaction_Amount DECIMAL(10,2),
    Date_of_Transaction DATE DEFAULT GETDATE(),
);


create or alter trigger trg_InsertIntoBankAndAccontHolderDetails
on account_opening_form
after update
as
begin
	declare @id int, @accountType varchar(50), @accountOpeningDate date, @currentBalance decimal(10, 2);
	declare @accountHolderName varchar(50), @dob date, @aadharNumber varchar(50), @mobileNumber varchar(50), @fullAddress varchar(50);

	select @id = id, @accountType = Account_type, @accountOpeningDate = [date], @currentBalance = Account_opening_balance, 
		@accountHolderName = Account_HolderName, @dob = DOB, @aadharNumber = AadharNumber, @mobileNumber = MobileNumber, @fullAddress = FullAddress
	from inserted 
	where KYC_Status = 'approved'

	if @id is not null
	begin	
		if not exists (select 1 from bank where initialId = @id)
		begin
			insert into bank(accountType, AccountOpeningDate, CurrentBalance, initialId) 
			values(@accountType, @accountOpeningDate, @currentBalance, @id);

			DECLARE @newAccountNumber BIGINT = SCOPE_IDENTITY();

			insert into account_holder_details(AccountNumber, Account_HolderName, DOB, AadharNumber, MobileNumber, FullAddress)
			values(@newAccountNumber, @accountHolderName, @dob, @aadharNumber, @mobileNumber, @fullAddress);
		end;
	end;
end;

Insert into account_opening_form 
(Account_type,Account_HolderName, DOB,AadharNumber,MobileNumber,Account_opening_balance,FullAddress)
values('saving','Navin','1999-08-24','575854562826','9568226569',1000,'delhi');

Insert into account_opening_form 
(Account_type,Account_HolderName, DOB,AadharNumber,MobileNumber,Account_opening_balance,FullAddress)
values('saving','Mahesh','1999-09-25','575854561111','9568226570',1020,'delhi');

Insert into account_opening_form 
(Account_type,Account_HolderName, DOB,AadharNumber,MobileNumber,Account_opening_balance,FullAddress)
values('saving','ABC','1999-12-25','575854561112','9568226571',1500,'delhi');

select * from account_opening_form
select * from account_holder_details
select * from bank
select * from transaction_details

UPDATE account_opening_form
SET KYC_Status = 'approved'
WHERE id = 1003;

CREATE PROCEDURE GetLastThreeMonthsAccountDetails
    @AccountNumber BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        td.TransactionID,
        td.Payment_Type,
        td.Transaction_Amount,
        td.Date_of_Transaction
    FROM 
        transaction_details td
    WHERE 
        td.AccountNumber = @AccountNumber
        AND td.Date_of_Transaction >= DATEADD(MONTH, -3, GETDATE())
    ORDER BY 
        td.Date_of_Transaction DESC;
END;

create or alter trigger trg_UpdateBankBalance
on transaction_details
after insert, update
as 
begin
	declare @accountNumber bigint, @currentBalance decimal(10, 2), @transactionAmount decimal(10, 2), @paymentType varchar(20);
	
	select @accountNumber = AccountNumber, @transactionAmount = Transaction_Amount, @paymentType = Payment_Type 
	from inserted 

	update bank
	set bank.CurrentBalance =
		CASE 
			when @paymentType = 'credit' then bank.CurrentBalance + @transactionAmount 
			when @paymentType = 'debit' then 
				case
					when bank.CurrentBalance >= @transactionAmount then bank.CurrentBalance - @transactionAmount
					else bank.CurrentBalance
				end
			else bank.CurrentBalance
		end
	where AccountNumber = @accountNumber
	
	print 'Updated balance'
end;

select * from bank
Insert into transaction_details
(AccountNumber, Payment_Type, Transaction_Amount)
values('123456790','credit','300');

Insert into transaction_details
(AccountNumber, Payment_Type, Transaction_Amount)
values('123456790','debit','2300');