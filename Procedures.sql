--procedure to find location's id or add this location if absent
create procedure findPlaceId(
@country varchar(40),
@city varchar(40),
@street varchar(40),
@postalCode varchar(8),
@placeID int output
)
as
    begin
        set @placeID = (select Place_ID from ConferencePlace where City = @city
                                                                and Country = @country
                                                                and Street = @street
                                                                and Postal_Code = @postalCode)

        if @placeID is null
        begin
            insert into ConferencePlace values (@country, @city, @street, @postalCode)
            set @placeID = @@IDENTITY
        end

    end


--procedure to add conference
create procedure addConference(
@name as varchar(100),
@startDate as date,
@endDate as date,
@country as varchar(40),
@city as varchar(40),
@street as varchar(40),
@postalCode as varchar(8),
@studentDiscount as decimal(3,2)
)
as
    begin
        if @endDate >= @startDate and @startDate > getdate()
            begin
                declare @PLACE_ID int -- place's id to be set into Conference table
                exec findPlaceId
                    @country,
                    @city,
                    @street,
                    @postalCode,
                    @placeID = @PLACE_ID output


                insert into Conferences values(@name, @startDate, @endDate, @PLACE_ID, @studentDiscount)
            end
        else
        begin
            raiserror ('Wrong dates!', -1 , -1 )
        end

    end

--procedure to add day conference
create procedure addConferenceDay(
@conferenceID as int,
@dayDate as date,
@participantsLimit as int,
@basePrice as money
)
as
    begin
        if @dayDate >= (select Conferences.Start_Date from Conferences where Conference_ID = @conferenceID)
               and @dayDate <= (select Conferences.End_Date from Conferences where Conference_ID = @conferenceID)
        begin
            insert into Conference_Day values (@conferenceID, @dayDate, @participantsLimit, @basePrice)
        end
        else
        begin
            raiserror ('Wrong dates!', -1 , -1)
        end
    end



--procedure to add workshop to day
create procedure addWorkshopToDay(
    @workshopID as int,
    @conferenceDayID as int,
    @participantsLimit as int,
    @price as money,
    @room as varchar(10),
    @from as time,
    @to as time
)
as
    begin
        if @from < @to
        begin
            insert into Workshops_In_Day values (@workshopID, @conferenceDayID, @participantsLimit, @price, @room, @from, @to)
        end
        else
        begin
            raiserror ('Wrong start and end hours!', -1, -1)
        end
    end


--add payment
create procedure addPayment(
    @reservationID int,
    @amount money
)
as
    begin
        if @amount != 0
        begin
            insert into Payment values (getdate(), @amount, @reservationID) -- amount > 0 isn't check because it is assumed that some money can be returned
        end
        else
        begin
            raiserror ('No money transferred', -1, -1)
        end
    end

create procedure addClient(
    @clientID int output
)
as
    begin
        insert into Client values ('') -- Bartek help, because it has only one autogenerated value
        set @clientID = @@IDENTITY
    end



--this procedure add new company to table company and add client for this company in table company
create procedure addCompany(
    @name varchar(40),
    @address varchar(40),
    @city varchar(40),
    @Country varchar(40),
    @Phone int,
    @Mail varchar(100),
    @Contact_Person varchar(50)
)
as
    begin
        declare @clientID int
        exec addClient
        @clientID = @clientID output

        insert into Company values (@name, @clientID, @address, @city, @Country, @Phone, @Mail, @Contact_Person)
    end



--this procedure add new person to table person and add client for this person in table company
create procedure addPerson(
    @firstName varchar(40),
    @lastName varchar(40),
    @address varchar(40),
    @city varchar(40),
    @country varchar(40),
    @phone int,
    @mail varchar(100)
)
as
    begin
        declare @clientID int
        exec addClient
        @clientID = @clientID output

        insert into Person values (@clientID, @firstName, @lastName, @address, @city, @country, @phone, @mail)

    end
