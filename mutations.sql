-- SELECT Database to use
USE JeffersonLibrary;

-- Variables:
    DECLARE
        @firstName          varchar,
        @mi                 char,
        @lastName           varchar,
        @tagName            varchar,
        @dob                date,
        @phone              varchar(15),
        @email              varchar(50),
        @todaysdate         date
        

SET @todaysdate = CONVERT(DATE, GETDATE());
    BEGIN

-- ================================================================
-- Insert Mutations
-- ================================================================

-- Authors
Insert into Authors (author_firstname, author_mi, author_lastname)
VALUES (@firstName, @mi, @lastName);

-- Tags
Insert into Tags (tag_name)
VALUES (@tagName);

-- Member
Insert into Members (firstname, lastname, date_of_birth, phone_number, email, membership_date)
VALUES (@firstName, @lastName, @dob, @phone, @email, @todaysdate)

-- ================================================================
-- Update Mutations
-- ================================================================



-- ================================================================
-- Delete Mutations
-- ================================================================

END;