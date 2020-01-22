-- Created by Vertabelo (http://vertabelo.com)
-- Last modification date: 2020-01-10 09:03:36.904

-- tables
-- Table: Client
CREATE TABLE Client (
    Client_ID int  NOT NULL IDENTITY(1,1) PRIMARY KEY
);

-- Table: Company
CREATE TABLE Company (
    ID int  NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Company_Name varchar(40)  NOT NULL,
    Client_ID int  NOT NULL,
    Address varchar(40)  NOT NULL,
    City varchar(40)  NOT NULL,
    Country varchar(40)  NOT NULL,
    Phone int  NOT NULL,
    Mail varchar(100)  NOT NULL,
    Contact_Person varchar(50)  NOT NULL
);

-- Table: ConferencePlace
CREATE TABLE ConferencePlace (
    Place_ID int  NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Country varchar(40)  NOT NULL,
    City varchar(40)  NOT NULL,
    Street varchar(40)  NOT NULL,
    Postal_Code varchar(8)  NOT NULL,
    CONSTRAINT uniqueAddress UNIQUE (Country, City, Street, Postal_Code)
);

-- Table: Conference_Day
CREATE TABLE Conference_Day (
    Conference_Day_ID int  NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Conference_ID int  NOT NULL,
    Date date  NOT NULL,
    Participants_Limit int  NOT NULL, check (Participants_Limit > 0),
    Base_Price money  NOT NULL, check (Base_Price > 0),
    Is_Cancelled bit  NOT NULL DEFAULT 0
);


-- Table: Conference_Day_Participants
CREATE TABLE Conference_Day_Participants (
    Person_ID int  NOT NULL,
    Reservation_ID int  NOT NULL,
	Student bit DEFAULT 0,
    CONSTRAINT Conference_Day_Participants_pk PRIMARY KEY  (Person_ID,Reservation_ID)
);

-- Table: Conferences
CREATE TABLE Conferences (
    Conference_ID int  NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Conference_Name varchar(100)  NOT NULL,
    Start_Date date  NOT NULL,
    End_Date date  NOT NULL,
    Place_ID int  NOT NULL,
    Student_Discount decimal(3,2)  NULL, check (Student_Discount >= 0 and Student_Discount <= 100), -- possible that students have free entry
    Is_Cancelled bit  NOT NULL DEFAULT 0
);

-- Table: Discounts
CREATE TABLE Discounts (
    Discount_ID int  NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Discount_Percentage decimal(2,2)  NOT NULL, check (Discount_Percentage >=0 and Discount_Percentage < 100),
    Days_Before_Conference int  NOT NULL, check (Days_Before_Conference > 0),
    Conference_Day_ID int  NOT NULL
);


-- Table: Payment
CREATE TABLE Payment (
    Payment_ID int  NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Payment_Date date  NOT NULL,
    Amount_Paid money  NOT NULL,
    Reservation_ID int  NOT NULL
);

-- Table: Person
CREATE TABLE Person (
    Person_ID int  NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Client_ID int  NOT NULL,
    First_Name varchar(40)  NOT NULL,
    Last_Name varchar(40)  NOT NULL,
    Address varchar(40)  NOT NULL,
    City varchar(40)  NOT NULL,
    Country varchar(40)  NOT NULL,
    Phone int  NOT NULL,
    Mail varchar(100)  NOT NULL
);

-- Table: Reservation
CREATE TABLE Reservation (
    Reservation_ID int  NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Reservation_Date date  NOT NULL,
    Normal_Ticket_Count int  NOT NULL, CHECK (Normal_Ticket_Count >= 0), -- we'll write procedure to ensure both tickets counts aren't 0
    Student_Ticket_Count int  NOT NULL, CHECK (Student_Ticket_Count >= 0),
    Amount_To_Pay money NOT NULL, CHECK (Amount_To_Pay >= 0),
    Client_ID int  NOT NULL,
    Conference_Day_ID int  NOT NULL,
    Is_Cancelled bit  NOT NULL DEFAULT 0
);

-- Table: Student
CREATE TABLE Student (
    Card_ID int NOT NULL IDENTITY (1,1) PRIMARY KEY , --alternative primary key
    Person_ID int  NOT NULL,
    University varchar(100)  NOT NULL,
    Faculty varchar(100)  NOT NULL,
    is_valid bit  NOT NULL DEFAULT 1
);

-- Table: Workshop_reservation
CREATE TABLE Workshop_reservation (
	Workshop_Reservation_ID int IDENTITY(1,1) PRIMARY KEY,
    Reservation_ID int  NOT NULL,
    Workshop_ID int  NOT NULL,
    Conference_Day_ID int  NOT NULL,
    Ticket_Count int  NOT NULL CHECK (Ticket_Count > 0),
    Is_Cancelled bit  NOT NULL DEFAULT 0,
);

-- Table: Workshops
CREATE TABLE Workshops (
    Workshop_ID int  NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Subject varchar(100)  NOT NULL,
    Description varchar(1000)
);

-- Table: Workshops_In_Day
CREATE TABLE Workshops_In_Day (
    Workshop_ID int  NOT NULL,
    Conference_Day_ID int  NOT NULL,
    Participants_Limit int  NOT NULL,
    Price money  NOT NULL CHECK (Price > 0),
    Room varchar(10)  NOT NULL,
    [From] time  NOT NULL,
    [To] time  NOT NULL,
    Is_Cancelled bit  NOT NULL DEFAULT 0,
    CONSTRAINT Workshops_In_Day_pk PRIMARY KEY  (Workshop_ID,Conference_Day_ID)
);

-- Table: Workshops_Participants
CREATE TABLE Workshops_Participants (
    Person_ID int  NOT NULL,
    Workshop_Reservation_ID int  NOT NULL,
    CONSTRAINT Workshops_Participants_pk PRIMARY KEY  (Person_ID, Workshop_Reservation_ID)
);

-- foreign keys
-- Reference: Company_Client (table: Company)
ALTER TABLE Company ADD CONSTRAINT Company_Client
    FOREIGN KEY (Client_ID)
    REFERENCES Client (Client_ID);

-- Reference: Conference_Day_Conferences (table: Conference_Day)
ALTER TABLE Conference_Day ADD CONSTRAINT Conference_Day_Conferences
    FOREIGN KEY (Conference_ID)
    REFERENCES Conferences (Conference_ID);

-- Reference: Conference_Day_Participants_Person (table: Conference_Day_Participants)
ALTER TABLE Conference_Day_Participants ADD CONSTRAINT Conference_Day_Participants_Person
    FOREIGN KEY (Person_ID)
    REFERENCES Person (Person_ID);

-- Reference: Conference_Day_Participants_Reservation (table: Conference_Day_Participants)
ALTER TABLE Conference_Day_Participants ADD CONSTRAINT Conference_Day_Participants_Reservation
    FOREIGN KEY (Reservation_ID)
    REFERENCES Reservation (Reservation_ID);

-- Reference: Conferences_ConferencePlace (table: Conferences)
ALTER TABLE Conferences ADD CONSTRAINT Conferences_ConferencePlace
    FOREIGN KEY (Place_ID)
    REFERENCES ConferencePlace (Place_ID);

-- Reference: Discounts_Conference_Day (table: Discounts)
ALTER TABLE Discounts ADD CONSTRAINT Discounts_Conference_Day
    FOREIGN KEY (Conference_Day_ID)
    REFERENCES Conference_Day (Conference_Day_ID);

-- Reference: Payment_Reservation (table: Payment)
ALTER TABLE Payment ADD CONSTRAINT Payment_Reservation
    FOREIGN KEY (Reservation_ID)
    REFERENCES Reservation (Reservation_ID);

-- Reference: Person_Client (table: Person)
ALTER TABLE Person ADD CONSTRAINT Person_Client
    FOREIGN KEY (Client_ID)
    REFERENCES Client (Client_ID);

-- Reference: Reservation_Client (table: Reservation)
ALTER TABLE Reservation ADD CONSTRAINT Reservation_Client
    FOREIGN KEY (Client_ID)
    REFERENCES Client (Client_ID);

-- Reference: Reservation_Conference_Day (table: Reservation)
ALTER TABLE Reservation ADD CONSTRAINT Reservation_Conference_Day
    FOREIGN KEY (Conference_Day_ID)
    REFERENCES Conference_Day (Conference_Day_ID);

-- Reference: Student_Person (table: Student)
ALTER TABLE Student ADD CONSTRAINT Student_Person
    FOREIGN KEY (Person_ID)
    REFERENCES Person (Person_ID);

-- Reference: Workshop_reservation_Reservation (table: Workshop_reservation)
ALTER TABLE Workshop_reservation ADD CONSTRAINT Workshop_reservation_Reservation
    FOREIGN KEY (Reservation_ID)
    REFERENCES Reservation (Reservation_ID);

-- Reference: Workshop_reservation_Workshops_In_Day (table: Workshop_reservation)
ALTER TABLE Workshop_reservation ADD CONSTRAINT Workshop_reservation_Workshops_In_Day
    FOREIGN KEY (Workshop_ID,Conference_Day_ID)
    REFERENCES Workshops_In_Day (Workshop_ID,Conference_Day_ID);

-- Reference: Workshops_In_Day_Conference_Day (table: Workshops_In_Day)
ALTER TABLE Workshops_In_Day ADD CONSTRAINT Workshops_In_Day_Conference_Day
    FOREIGN KEY (Conference_Day_ID)
    REFERENCES Conference_Day (Conference_Day_ID);

-- Reference: Workshops_In_Day_Workshops (table: Workshops_In_Day)
ALTER TABLE Workshops_In_Day ADD CONSTRAINT Workshops_In_Day_Workshops
    FOREIGN KEY (Workshop_ID)
    REFERENCES Workshops (Workshop_ID);

-- Reference: Workshops_Participants_Person (table: Workshops_Participants)
ALTER TABLE Workshops_Participants ADD CONSTRAINT Workshops_Participants_Person
    FOREIGN KEY (Person_ID)
    REFERENCES Person (Person_ID);

-- Reference: Workshops_Participants_Workshop_reservation (table: Workshops_Participants)
ALTER TABLE Workshops_Participants ADD CONSTRAINT Workshops_Participants_Workshop_reservation
    FOREIGN KEY (Workshop_Reservation_ID)
    REFERENCES Workshop_reservation (Workshop_Reservation_ID);

-- End of file.

