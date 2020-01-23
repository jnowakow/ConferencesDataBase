--procedure to find location's id or add this location if absent
create procedure addPlace(
@country varchar(40),
@city varchar(40),
@street varchar(40),
@postalCode varchar(8),
@placeID int output


)
as
    if @placeID is null
    begin
        insert into Conference_Place values (@country, @city, @street, @postalCode)
        set @placeID = @@IDENTITY
    end

--procedure to add conference
create or alter procedure addConference(
@name as varchar(100),
@startDate as date,
@endDate as date,
@placeID as int,
@studentDiscount as decimal(5,2),
@conferenceID as int output
)
as
    begin
        if @endDate >= @startDate and @startDate > convert(date, getdate())
            begin
                insert into Conference(Conference_Name, Start_Date, End_Date, Place_ID, Student_Discount) values(@name, @startDate, @endDate, @placeID, @studentDiscount)
                set @conferenceID = @@IDENTITY
            end
        else
        begin
            raiserror ('Wrong dates!', -1 , -1 )
        end

    end

--procedure to add day conference
create or alter procedure addConferenceDay(
@conferenceID as int,
@date as date,
@participantsLimit as int,
@basePrice as money,
@conferenceDayID as int output
)
as
    begin 
        if @date >= (select Conference.Start_Date from Conference where Conference_ID = @conferenceID)
            and @date <= (select Conference.End_Date from Conference where Conference_ID = @conferenceID)
            and @date not in (select Conference_Day.Date from Conference_Day where Conference_ID = @conferenceID)
        begin
            insert into Conference_Day(Conference_ID, Date, Participants_Limit, Base_Price)
            values (@conferenceID, @date, @participantsLimit, @basePrice)

            set @conferenceDayID = @@IDENTITY
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
            insert into Workshop_In_Day(workshop_id, conference_day_id, participants_limit, price, room, [from], [to])
            values (@workshopID, @conferenceDayID, @participantsLimit, @price, @room, @from, @to)
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
            insert into Payment values (convert(date, getdate()), @amount, @reservationID) -- amount > 0 isn't check because it is assumed that some money can be returned
        end
        else
        begin
            raiserror ('No money transferred', -1, -1)
        end
    end

create procedure returnWholePayment(
    @reservationID int,
    @amountToReturn money output
)
as
    begin
        set @amountToReturn = (select sum(Amount_Paid)
                               from Payment
                               where Reservation_ID = @reservationID)

        insert into Payment(Payment_Date, Amount_Paid, Reservation_ID) values (convert(date, getdate()), -@amountToReturn, @reservationID)
    end

create procedure returnOverpaidAmount(
    @reservationID int,
    @overpaidAmount money output
)
as
    begin
        declare @sumForConference money
        set @sumForConference = (select sum(dbo.SumToPay(Conference_Day_ID, Normal_Ticket_Count, Student_Ticket_Count))
                            from Reservation
                            where Reservation_ID = @reservationID)

        declare @sumForWorkshops money
        set @sumForWorkshops = (select sum(dbo.SumToPayForWorkshop(Workshop_ID, Conference_Day_ID, Ticket_Count))
                                from Workshop_reservation
                                where Reservation_ID = @reservationID)

        set @overpaidAmount = (select sum(Payment.Amount_Paid)
                                from Payment
                                where Reservation_ID = @reservationID) - (@sumForConference + @sumForWorkshops)

        insert into Payment(Payment_Date, Amount_Paid, Reservation_ID) values (convert(date, getdate()), - @overpaidAmount, @reservationID )

    end

create procedure addClient(
    @clientID int output
)
as
    begin
        insert into Client default values
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

create or alter procedure addReservation(
    @normalTicketCount int,
    @studentTicketCount int,
    @clientID int,
    @conferenceDayID int,
    @reservationID int output
)
as
    begin
        if ((select dbo.FreePlacesForConferenceDay(@conferenceDayID)) >= @normalTicketCount + @studentTicketCount)
        begin

            insert into Reservation(Reservation_Date, Normal_Ticket_Count, Student_Ticket_Count, Client_ID, Conference_Day_ID)
            values (convert(date, getdate()), @normalTicketCount, @studentTicketCount, @clientID, @conferenceDayID)
            set @reservationID = @@IDENTITY
        end
        else
        begin
            raiserror ('Too few tickets left!', -1 , -1)
        end
    end


create or alter procedure addPersonToReservation(
	@reservationID int,
	@personID int,
	@isStudent bit
	)
as
	begin
		insert into Conference_Day_Participant(Person_ID, Reservation_ID, Student) values (@personID, @reservationID, @isStudent)
	end

create or alter procedure addPersonToWorkshopReservation(
	@personID int,
	@workshopReservationID int
	)
as
	begin
		declare @reservationID int = (select Reservation_ID
		                              from Workshop_Reservation
		                              where Workshop_Reservation_ID = @workshopReservationID)

		if @personID in (select Person_ID from Conference_Day_Participant where Reservation_ID = @reservationID)
		begin
	        insert into Workshop_Participant(Person_ID, Workshop_Reservation_ID) values (@personID, @workshopReservationID)
	    end
	    else
	    begin
            raiserror ('Person must be conference day participant', -1, -1)
        end
	end



create or alter procedure addWorkshopReservation(
        @reservationID int,
        @workshopID int,
        @conferenceDayID int,
        @ticketsCount int,
        @workshopReservationID int output
)
as
    begin
        if @ticketsCount < (select dbo.FreePlacesForWorkshopInDay(@workshopID, @conferenceDayId))
        begin

            insert into Workshop_Reservation(reservation_id, workshop_id, conference_day_id, ticket_count)
             values (@reservationID, @workshopID, @conferenceDayID, @ticketsCount)
            set @workshopReservationID = @@IDENTITY
        end
        else
        begin
            raiserror ('Too few tickets left for this workshop!', -1, -1)
        end
    end


--Procedure to add discount for day
create or alter procedure addDiscountToDay(
    @percentage decimal(5,2),
    @daysBefore int,
    @conferenceDayID int
)
as
    begin
        declare @conferenceDayDate date =
            (select Conference_Day.Date from Conference_Day where Conference_Day_ID = @conferenceDayID)

        if datediff(day, @conferenceDayDate, getdate()) > @daysBefore
            begin
                insert into Discount values (@percentage, @daysBefore, @conferenceDayID)
            end
    end


create procedure addWorkshop (
	@subject varchar (100),
	@description varchar (1000),
	@workshopID int output
)
as
	begin
		insert into Workshop values (@subject, @description)
		set @workshopID = @@IDENTITY
	end


create procedure addStudentCard (
	@personID int,
	@university varchar(100),
	@faculty varchar(100),
	@cardId int output
)
as
	begin
		insert into Student(person_id, university, faculty) values (@personID, @university, @faculty)
	    set @cardId = @@IDENTITY
	end


create procedure cancelReservation(
    @reservationID int
)
as
    begin
        update Reservation
        set Is_Cancelled = 1
        where Reservation_ID = @reservationID
    end

create procedure cancelWorkshopReservation(
    @workshopReservationID int
)
as
    begin
        update Workshop_reservation
        set Is_Cancelled = 1
        where Workshop_Reservation_ID = @workshopReservationID

    end

create procedure cancelConferenceDay(
    @conferenceDayID int
)
as
    begin
        update Conference_Day
        set Is_Cancelled = 1
        where Conference_Day_ID = @conferenceDayID
    end

create procedure cancelConference(
    @conferenceID int
)
as
    begin
        update Conference
        set Is_Cancelled = 1
        where Conference_ID = @conferenceID
    end