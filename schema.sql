-- Create the database
    CREATE DATABASE 'JeffersonLibrary';

-- Use the database
    USE 'JeffersonLibrary';

-- ================================================================
-- Create the tables
-- ================================================================
-- Create the Members table
create table dbo.Members
(
    memberId        int identity (110, 1)
        constraint Members_pk
            primary key,
    firstname       nvarchar(50) not null,
    lastname        nvarchar(50) not null,
    date_of_birth   date         not null,
    phone_number    nvarchar(15) not null,
    email           nvarchar(50) not null,
    membership_date date         not null
)
go

-- Create the FineStatus table
create table dbo.FineStatus
(
    fine_status_id   int identity
        constraint FineStatus_pk
            primary key,
    fine_status_name nvarchar(50) not null
)
go
-- Create the Tags table
create table dbo.Tags
(
    tag_id   int identity
        constraint Tags_pk
            primary key,
    tag_name nvarchar(50) not null
)
go
-- Create the BookRatings table
create table dbo.BookRatings
(
    rating_id int identity
        constraint BookRatings_pk
            primary key,
    rating    nvarchar(50) not null
)
go

-- Create the Authors table
create table dbo.Authors
(
    author_id        int identity (100, 1)
        constraint Authors_pk
            primary key,
    author_firstname nvarchar(50) not null,
    author_mi        char,
    author_lastname  nvarchar(50) not null
)
go
-- Create the Books table
create table dbo.Books
(
    book_id          int identity (1272, 1)
        constraint Books_pk
            primary key,
    isbn_number      bigint        not null
        constraint Books_pk_2
            unique,
    book_title       nvarchar(50)  not null,
    publisher        nvarchar(50)  not null,
    page_count       int           not null,
    rating_id        int           not null
        constraint Books_BookRatings_rating_id_fk
            references dbo.BookRatings,
    cost             decimal(6, 2) not null,
    copies_available tinyint       not null,
    published_year   int           not null
)
go
-- Create the BookTags table
create table dbo.BookTags
(
    tag_id  int not null
        constraint BookTags_Tags_tag_id_fk
            references dbo.Tags,
    book_id int not null
        constraint BookTags_Books_book_id_fk
            references dbo.Books
)
go

-- Create the BookAuthors table
create table dbo.BookAuthors
(
    author_id int not null
        constraint BookAuthors_Authors_author_id_fk
            references dbo.Authors,
    book_id   int not null
        constraint BookAuthors_Books_book_id_fk
            references dbo.Books
)
go
-- Create the Reservations table
create table dbo.Reservations
(
    reservation_id         int identity
        constraint Reservations_pk
            primary key,
    member_id              int     not null
        constraint Reservations_Members_memberId_fk
            references dbo.Members,
    reservation_created_on date    not null,
    reserved_items_count   tinyint not null,
    reservation_held_until date    not null
)
go
-- Create the Loans table
create table dbo.Loans
(
    loan_id            int identity (500, 1)
        constraint Loans_pk
            primary key,
    member_id          int     not null
        constraint Loans_Members_memberId_fk
            references dbo.Members,
    loan_date          date    not null,
    due_date           date,
    loaned_items_count tinyint not null
)
go
-- Create the Fines table
create table dbo.Fines
(
    fine_id          int identity
        constraint Fines_pk
            primary key,
    loan_id          int           not null
        constraint Fines_Loans_loan_id_fk
            references dbo.Loans,
    fine_amount      decimal(6, 2) not null,
    fine_incurred_on date          not null,
    fine_status_id   int           not null
        constraint Fines_FineStatus_fine_status_id_fk
            references dbo.FineStatus
)
go
-- Create the ActivityTypes table
create table dbo.ActivityTypes
(
    activity_type_id   int          not null
        constraint ActivityTypes_pk
            primary key,
    activity_type_name nvarchar(50) not null
)
go
-- Create the ActivityLog table
create table dbo.ActivityLog
(
    activity_id      int identity (800, 1)
        constraint ActivityLog_pk
            primary key,
    activity_type_id int  not null
        constraint ActivityLog_ActivityTypes_activity_type_id_fk
            references dbo.ActivityTypes,
    member_id        int  not null
        constraint ActivityLog_Members_memberId_fk
            references dbo.Members,
    activity_date    date not null
)
go
-- Create the BooksOnLoan table
create table dbo.BooksOnLoan
(
    loan_id int not null
        constraint BooksOnLoan_Loans_loan_id_fk
            references dbo.Loans,
    book_id int not null
        constraint BooksOnLoan_Books_book_id_fk
            references dbo.Books
)
go


-- Create the ReservedBooks table
create table dbo.ReservedBooks
(
    reservation_id int not null
        constraint ReservedBooks_Reservations_reservation_id_fk
            references dbo.Reservations,
    book_id        int not null
        constraint ReservedBooks_Books_book_id_fk
            references dbo.Books
)
go

-- ================================================================
-- Create stored procedures
-- ================================================================

-- Add new book
create procedure uspAddNewBook
(
    @isbn_number bigint,
    @book_title nvarchar(50),
    @author_firstname nvarchar(50),
    @author_mi char(1) = NULL,
    @author_lastname nvarchar(50),
    @publisher nvarchar(50),
    @page_count int,
    @rating_id int = 0,
    @cost decimal(6,2),
    @copies_available tinyint,
    @published_year int,
    @genre nvarchar(50),
    @tag1 nvarchar(50) = NULL,
    @tag2 nvarchar(50) = NULL,
    @tag3 nvarchar(50) = NULL,
    @tag4 nvarchar(50) = NULL,
    @tag5 nvarchar(50) = NULL
)
as
    BEGIN TRANSACTION;
BEGIN TRY
    -- ISBN must be 10 or 13 digits long
    IF (LEN(CAST(@isbn_number AS VARCHAR)) != 10 and LEN(CAST(@isbn_number  AS VARCHAR)) != 13)
        BEGIN
            RAISERROR ('Invalid ISBN, Please enter a valid ISBN', 16, 10);
        end
    -- Rating ID must exist in the Book Ratings table
    IF NOT EXISTS (select rating_id from BookRatings where rating_id = @rating_id)
        BEGIN
            RAISERROR ('Invalid Rating ID, Please enter a valid Rating ID', 16, 10);
        end
    -- Published year must be valid
    IF NOT (@published_year between 1900 AND 2050)
        begin
            RAISERROR ('Invalid Year, Please enter a year in the "YYYY" format', 16, 10);
        end
    -- Declaring variables:
    DECLARE @bookid int,
        @authorid int,
        @genreid int,
        @tag1id int,
        @tag2id int,
        @tag3id int,
        @tag4id int,
        @tag5id int;

    -- Insert Book into Books
    INSERT INTO Books (isbn_number, book_title, publisher, page_count, rating_id, cost, copies_available, published_year)
    VALUES (
               @isbn_number,
               @book_title,
               @publisher,
               @page_count,
               @rating_id,
               @cost,
               @copies_available,
               @published_year
           )

    -- Retrieve the ID of the newly inserted book
    SET @bookid = SCOPE_IDENTITY();

    -- Insert Author into Authors
    IF NOT EXISTS(
        SELECT author_id FROM Authors
        WHERE author_firstname = @author_firstname AND
            author_lastname = @author_lastname AND
            author_mi = @author_mi)
        BEGIN
            insert into Authors (author_firstname, author_mi, author_lastname)
            values (@author_firstname, @author_mi, @author_lastname);
            -- Retrieve the ID of the newly inserted AUTHOR
            SET @authorid = SCOPE_IDENTITY();
        END
    ELSE
        BEGIN
            -- Set the id of existing AUTHOR
            SET @authorid = (
                SELECT author_id FROM Authors
                WHERE author_firstname = @author_firstname AND
                    author_lastname = @author_lastname AND
                    author_mi = @author_mi)
        END

    -- Insert Genre into Tags
    IF NOT EXISTS(SELECT tag_id FROM Tags WHERE tag_name = @genre)
        BEGIN
            insert into Tags (tag_name)
            values (@genre)
            -- Retrieve the ID of the newly inserted Tag
            SET @genreid = SCOPE_IDENTITY();
        END
    ELSE
        BEGIN
            -- Set the id of existing tag
            SET @genreid = (select tag_id from Tags WHERE tag_name = @genre);
        END

    -- Insert TAG1 into Tags IF IT EXISTS
    IF (@tag1 IS NOT NULL AND (
        NOT EXISTS(SELECT tag_id FROM Tags WHERE tag_name = @tag1)
        ))
        BEGIN
            -- Insert @TAG1 into Tags
            insert into Tags (tag_name)
            values (@tag1)
            -- Retrieve the ID of the newly inserted Tag
            SET @tag1id = SCOPE_IDENTITY();
        END
    ELSE IF (@tag1 IS NOT NULL AND (
        EXISTS(SELECT tag_id FROM Tags WHERE tag_name = @tag1)
        ))
        BEGIN
            -- Set the id of existing tag
            SET @tag1id = (SELECT tag_id FROM Tags WHERE tag_name = @tag1);
        end

    -- Insert TAG2 into Tags IF IT EXISTS
    IF (@tag2 IS NOT NULL AND (
        NOT EXISTS(SELECT tag_id FROM Tags WHERE tag_name = @tag2)
        ))
        BEGIN
            -- Insert @TAG2 into Tags
            insert into Tags (tag_name)
            values (@tag2)
            -- Retrieve the ID of the newly inserted Tag
            SET @tag2id = SCOPE_IDENTITY();
        END
    ELSE IF (@tag2 IS NOT NULL AND (
        EXISTS(SELECT tag_id FROM Tags WHERE tag_name = @tag2)
        ))
        BEGIN
            -- Set the id of existing tag
            SET @tag2id = (SELECT tag_id FROM Tags WHERE tag_name = @tag2);
        end

    -- Insert TAG3 into Tags IF IT EXISTS
    IF (@tag3 IS NOT NULL AND (
        NOT EXISTS(SELECT tag_id FROM Tags WHERE tag_name = @tag3)
        ))
        BEGIN
            -- Insert @TAG3 into Tags
            insert into Tags (tag_name)
            values (@tag3)
            -- Retrieve the ID of the newly inserted Tag
            SET @tag3id = SCOPE_IDENTITY();
        END
    ELSE IF (@tag3 IS NOT NULL AND (
        EXISTS(SELECT tag_id FROM Tags WHERE tag_name = @tag3)
        ))
        BEGIN
            -- Set the id of existing tag
            SET @tag3id = (SELECT tag_id FROM Tags WHERE tag_name = @tag3);
        end

    -- Insert TAG4 into Tags IF IT EXISTS
    IF (@tag4 IS NOT NULL AND (
        NOT EXISTS(SELECT tag_id FROM Tags WHERE tag_name = @tag4)
        ))
        BEGIN
            -- Insert @TAG4 into Tags
            insert into Tags (tag_name)
            values (@tag4)
            -- Retrieve the ID of the newly inserted Tag
            SET @tag4id = SCOPE_IDENTITY();
        END
    ELSE IF (@tag4 IS NOT NULL AND (
        EXISTS(SELECT tag_id FROM Tags WHERE tag_name = @tag4)
        ))
        BEGIN
            -- Set the id of existing tag
            SET @tag4id = (SELECT tag_id FROM Tags WHERE tag_name = @tag4);
        end

    -- Insert TAG5 into Tags IF IT EXISTS
    IF (@tag5 IS NOT NULL AND (
        NOT EXISTS(SELECT tag_id FROM Tags WHERE tag_name = @tag5)
        ))
        BEGIN
            -- Insert @TAG5 into Tags
            insert into Tags (tag_name)
            values (@tag5)
            -- Retrieve the ID of the newly inserted Tag
            SET @tag5id = SCOPE_IDENTITY();
        END
    ELSE IF (@tag5 IS NOT NULL AND (
        EXISTS(SELECT tag_id FROM Tags WHERE tag_name = @tag5)
        ))
        BEGIN
            -- Set the id of existing tag
            SET @tag5id = (SELECT tag_id FROM Tags WHERE tag_name = @tag5);
        end

    -- Insert into BookAuthors
    BEGIN
        insert into BookAuthors (author_id, book_id)
        values (@authorid, @bookid)
    END

    -- Insert into BookTags
    BEGIN
        INSERT INTO BookTags (tag_id, book_id)
        values  (@genreid, @bookid)
    END
    IF @tag1 IS NOT NULL
        BEGIN
            INSERT INTO BookTags (tag_id, book_id)
            values  (@tag1id, @bookid)
        END
    IF @tag2 IS NOT NULL
        BEGIN
            INSERT INTO BookTags (tag_id, book_id)
            values  (@tag2id, @bookid)
        END
    IF @tag3 IS NOT NULL
        BEGIN
            INSERT INTO BookTags (tag_id, book_id)
            values  (@tag3id, @bookid)
        END
    IF @tag4 IS NOT NULL
        BEGIN
            INSERT INTO BookTags (tag_id, book_id)
            values  (@tag4id, @bookid)
        END
    IF @tag5 IS NOT NULL
        BEGIN
            INSERT INTO BookTags (tag_id, book_id)
            values  (@tag5id, @bookid)
        END
    COMMIT TRANSACTION;
    PRINT('SUCCESSFULLY ADDED ' + @book_title);
end try
begin catch
    DECLARE @error int,
        @message varchar(4000)
    SELECT
        @error = ERROR_NUMBER(),
        @message = ERROR_MESSAGE()
    ROLLBACK TRANSACTION;
    RAISERROR ('Something went wrong, Transaction Rolled Back!', 16, 10, @error, @message);
end catch;
go

-- Delete an author
create procedure uspDeleteAuthor
(
    @authorid int
)
as
BEGIN
    IF EXISTS (select * from BookAuthors where author_id = @authorid)
        BEGIN
            RAISERROR ('There are books associated with this author, this author cannot be deleted', 16, 10);
        END
    ELSE
        BEGIN
            DELETE FROM Authors
            WHERE author_id = @authorid
        END
END
go



-- ================================================================
-- Create Triggers
-- ================================================================

-- Trigger on BookTags table
create trigger tagDeleted
    on BookTags
    for delete
    as
    Declare
        @tagid int
begin
    if @@ROWCOUNT >= 1
        begin
            IF EXISTS(select 1 from deleted)
                begin
                    set @tagid = (select top 1 tag_id from deleted)
                    DELETE FROM Tags
                    where tag_id = @tagid
                end
        end
end;
go

-- ================================================================
-- Create views
-- ================================================================