create or alter trigger ConferenceCancellation
    on Conference
    for update
    as
    begin
        if update(Is_Cancelled)
        begin
            if ((select Is_Cancelled from inserted) = 1)
            begin

                create table #daysToCancel(
                        dayID int
                )

                insert into #daysToCancel
                select Conference_Day_ID
                from Conference_Day
                where Conference_Day.Conference_ID = (select Conference_ID from inserted)

                update Conference_Day
                set Is_Cancelled = 1
                where Conference_Day.Conference_Day_ID in (select * from #daysToCancel)

                drop table #daysToCancel
            end
        end
    end

create or alter trigger ConferenceDayCancellation
    on Conference_Day
    for update
    as
    begin
        if update(Is_Cancelled)
            begin

                    create table #reservationsToCancel(
                        reservationID int
                    )

                    insert into #reservationsToCancel
                    select Reservation_ID
                    from Reservation
                    where Reservation.Conference_Day_ID in (select Conference_Day_ID
                                                            from inserted
                                                            where inserted.Is_Cancelled = 1)

                    update Reservation
                    set Is_Cancelled = 1
                    where Reservation_ID in (select * from #reservationsToCancel)

                    drop table #reservationsToCancel
            end
    end


create or alter trigger ReservationCancellation
    on Reservation
    after update
    as
    begin
        if update(Is_Cancelled)
        begin
                delete from Conference_Day_Participant --remove all people with this reservation from participants list
                where Reservation_ID in (select Reservation_ID from inserted)

                create table #workshopReservationsToCancel(
                    workshopReservationID int
                )

                insert into #workshopReservationsToCancel
                select Workshop_Reservation_ID
                from Workshop_reservation
                where Workshop_reservation.Reservation_ID in (select Reservation_ID
                                                              from inserted
                                                              where inserted.Is_Cancelled = 1)

                update Workshop_reservation
                set Is_Cancelled = 1
                where Workshop_Reservation_ID in (select * from #workshopReservationsToCancel)

                drop table #workshopReservationsToCancel

        end
    end


create or alter trigger WorkshopReservationCancellation
    on Workshop_reservation
    after update
    as
    begin
        if update(Is_Cancelled)
        begin

                delete from Workshop_Participant --remove all people with this reservation from participants list
                where Workshop_Reservation_ID in (select Workshop_Reservation_ID
                                                  from inserted
                                                  where inserted.Is_Cancelled = 1)
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
    on Workshop_In_Day

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
                    and Workshop_Reservation.Workshop_ID = inserted.Workshop_ID
                    and Workshop_Reservation.Is_Cancelled = 0
            ), 0)
            begin
                update Workshop_In_Day set Participants_Limit = deleted.Participants_Limit
                from dbo.Workshop_In_Day
                inner join deleted
                on Workshop_In_Day.Conference_Day_ID = deleted.Conference_Day_ID
                and Workshop_In_Day.Workshop_ID = deleted.Workshop_ID

                raiserror ('You cannot set participants limit to value smaller than current reservations', 16, 1);
                rollback transaction;
                return;
            end


        end
    end

	
create or alter trigger ConcurrentWorkshopParticipation
on Workshop_Participant
instead of insert
as
begin
	if exists(select *
				from inserted
					inner join Workshop_reservation as outerRes
						on outerRes.Workshop_Reservation_ID = inserted.Workshop_Reservation_ID
					inner join Workshop_In_Day as outerWork
						on outerWork.Conference_Day_ID = outerRes.Conference_Day_ID
							and outerWork.Workshop_ID = outerRes.Workshop_ID
				where exists(
					select *
					from Workshop_Participant
						inner join Workshop_reservation
							on Workshop_reservation.Workshop_Reservation_ID = Workshop_Participant.Workshop_Reservation_ID
					        and Workshop_Reservation.Is_Cancelled = 0
						inner join Workshop_In_Day
							on Workshop_In_Day.Conference_Day_ID = Workshop_reservation.Conference_Day_ID
								and Workshop_In_Day.Workshop_ID = Workshop_reservation.Workshop_ID
					where
						Workshop_Participant.Person_ID = inserted.Person_ID
						and Workshop_In_Day.Conference_Day_ID = outerWork.Conference_Day_ID
						and outerWork.[From] between Workshop_In_Day.[From] and Workshop_In_Day.[To]
						))
			begin
			raiserror ('You cannot reserve a workshop if you already reserved another workshop at the same time', 16, 1);
			rollback transaction;
			return ;
			end
		else
		begin
			insert into  Workshop_Participant(
				Person_ID,
				Workshop_Reservation_ID)
			select Person_ID, Workshop_Reservation_ID
			from inserted
		end
end

