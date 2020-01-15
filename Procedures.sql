--procedure to find location's id or add this location if absent
create procedure findPlace(
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
        if @endDate >= @startDate
            begin



                declare @PLACE_ID int -- place's id to be set into Conference table
                exec findPlace
                    @country,
                    @city,
                    @street,@postalCode,
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
