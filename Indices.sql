create nonclustered index Conferences_idx
on Conference_Day(Conference_ID desc)

create nonclustered index Discount_ConferenceDay_idx
on Discount( Conference_Day_ID desc )

create nonclustered index Company_Client_idx
on Company(Client_ID desc )

create nonclustered index Person_Client_idx
on Person(Client_ID desc )

create nonclustered index Student_Person_idx
on Student(Person_ID desc )

create nonclustered index Payment_Reservation_idx
on Payment(Reservation_ID desc )

create nonclustered index Conference_Place_idx
on Conference(Place_ID desc )

create nonclustered index Reservation_Client_idx
on Reservation(Client_ID desc )

create nonclustered index Reservation_ConferenceDay_idx
on Reservation(Conference_Day_ID desc )

create nonclustered index WorkshopReservation_Reservation_idx
on Workshop_reservation(Reservation_ID desc )

create nonclustered index WorkshopReservation_Workshop_idx
on Workshop_reservation(Workshop_ID desc )

create nonclustered index WorkshopReservation_ConferenceDay_idx
on Workshop_reservation(Conference_Day_ID desc )

