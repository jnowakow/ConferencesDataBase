create trigger ConferenceCancellation
    on Conferences
    after update
    as
    begin
        if update(Is_Cancelled)
        begin
            if (select Is_Cancelled from inserted) = 1
            begin
                declare @daysToCancel table (
                        dayID int
                )
                insert into @daysToCancel
                select Conference_Day_ID
                from u_kaszuba.dbo.Conference_Day
                where Conference_Day.Conference_ID = (select Conference_ID from inserted)

                update u_kaszuba.dbo.Conference_Day
                set Is_Cancelled = 1
                where Conference_Day_ID in @daysToCancel

            end
        end
    end

create trigger ConferenceDayCancellation
    on u_kaszuba.dbo.Conference_Day
    after update
    as
    begin
        if update(Is_Cancelled)
            begin
                if (select  Is_Cancelled from inserted) = 1
                begin

                    declare @reservationsToCancel table (
                        reservationID int
                    )
                    insert into @reservationsToCancel
                    select Reservation_ID
                    from u_kaszuba.dbo.Reservation
                    where Reservation.Conference_Day_ID = (select Conference_Day_ID from inserted)

                    update u_kaszuba.dbo.Reservation
                    set Is_Cancelled = 1
                    where Reservation_ID in @reservationsToCancel

                end
            end

    end


create trigger ReservationCancellation
    on u_kaszuba.dbo.Reservation
    after update
    as
    begin
        if update(Is_Cancelled)
        begin
            if (select Is_Cancelled from inserted) = 1
            begin

                delete from Conference_Day_Participants --remove all people with this reservation from participants list
                where Reservation_ID = (select Reservation_ID from inserted)

                declare @workshopReservationsToCancel table (
                    workshopReservationID int
                )
                insert into @workshopReservationsToCancel
                select Workshop_Reservation_ID
                from u_kaszuba.dbo.Workshop_reservation
                where Workshop_reservation.Reservation_ID = (select Reservation_ID from inserted)

                update u_kaszuba.dbo.Workshop_reservation
                set Is_Cancelled = 1
                where Workshop_Reservation_ID in @workshopReservationsToCancel

            end
        end
    end


create trigger WorkshopReservationCancellation
    on Workshop_reservation
    after update
    as
    begin
        if update(Is_Cancelled)
        begin
            if (select Is_Cancelled from inserted) = 1
            begin

                delete from Workshops_Participants --remove all people with this reservation from participants list
                where Workshop_Reservation_ID = (select Workshop_Reservation_ID from inserted)

            end
        end
    end

create or alter trigger DayConferenceParticipantsLimitChange
    on Conference_Day
    for update
    as
    begin
        if update(Participants_Limit)
        begin
            if (select Participants_Limit from inserted)  
			< 
			ISNULL((select sum(Normal_Ticket_Count + Student_Ticket_Count)
			from inserted
				inner join Reservation
					ON Reservation.Conference_Day_ID = inserted.Conference_Day_ID
			), 0)
            begin
				update Conference_Day set Participants_Limit = deleted.Participants_Limit
				from dbo.Conference_Day 
				inner join deleted
				on Conference_Day.Conference_Day_ID = deleted.Conference_Day_ID
                raiserror ('You cannot set participants limit to value smaller than current reservations', 16, 1);
				rollback transaction;
				return;
            end
			

        end
	end
	end

create or alter trigger WorkshopConferenceParticipantsLimitChange
    on Workshops_In_Day
    for update
    as
    begin
        if update(Participants_Limit)
        begin
            if (select Participants_Limit from inserted)  
			< 
			ISNULL((select sum(Workshop_Reservation.Ticket_Count)
			from inserted
				inner join Workshop_reservation
					on Workshop_reservation.Conference_Day_ID = inserted.Conference_Day_ID
				    and Workshop_Reservation.Workshop_Reservation_ID = inserted.Workshop_ID
			        and Workshop_Reservation.Is_Cancelled = 0
			),0)
            begin
				update Workshop_In_Day set Participants_Limit = deleted.Participants_Limit
				from dbo.Workshop_In_Day 
				inner join deleted
				on Workshop_In_Day.Conference_Day_ID = deleted.Conference_Day_ID
				and Workshop_In_Day.Workshop_ID = deleted.Workshop_ID
                
                raiserror ('You cannot set participants limet to value smaller than current reservations', 16, 1);
				rollback transaction;
				return;
            end
			
        end
	end


	
CREATE OR ALTER TRIGGER ConcurrentWorkshopParticipation
ON Workshops_Participants
INSTEAD OF INSERT
AS
BEGIN
	If EXISTS(Select *
				from inserted
					inner join Workshop_reservation as outerRes
						on outerRes.Workshop_Reservation_ID = inserted.Workshop_Reservation_ID
					inner join Workshops_In_Day as outerWork
						on outerWork.Conference_Day_ID = outerRes.Conference_Day_ID
							and outerWork.Workshop_ID = outerRes.Workshop_ID
				where EXISTS (
					Select *
					from Workshops_Participants
						inner join Workshop_reservation
							on Workshop_reservation.Workshop_Reservation_ID = Workshops_Participants.Workshop_Reservation_ID
						inner join Workshops_In_Day
							on Workshops_In_Day.Conference_Day_ID = Workshop_reservation.Conference_Day_ID
								and Workshops_In_Day.Workshop_ID = Workshop_reservation.Workshop_ID
					where
						Workshops_Participants.Person_ID = inserted.Person_ID
						and Workshops_In_Day.Conference_Day_ID = outerWork.Conference_Day_ID
						and outerWork.[From] Between Workshops_In_Day.[From] and Workshops_In_Day.[To]
						))
			Begin
			RAISERROR ('You cannot reserve a workshop if you already reserved another workshop at the same time', 16, 1);
			ROLLBACK TRANSACTION;
			RETURN;
			end
		Else
		begin
			INSERT INTO  Workshops_Participants( 
				Person_ID,
				Workshop_Reservation_ID)
			SELECT Person_ID, Workshop_Reservation_ID 
			FROM inserted
		end
END
