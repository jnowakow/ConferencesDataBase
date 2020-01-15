CREATE FUNCTION SplitList -- Function splits list passed as an argument based on the delimiter character (useful for parsing CSV lists)
(
   @List       VARCHAR(MAX),
   @Delimiter  CHAR(1)
)
RETURNS @ResultTable TABLE (items varchar(50))
AS
BEGIN 
	declare @item varchar(8)
	declare @separatorPosition int

	if len(@List) < 1 or @List is NULL return

	select @separatorPosition = -1


	while @separatorPosition <> 0
	BEGIN
		set @separatorPosition = CHARINDEX(@Delimiter,@List,0)

		if @separatorPosition != 0
			set @item = SUBSTRING(@List,0, @separatorPosition)
		else
			set @item = @List

		if (len(@item) > 0)
		BEGIN
			Insert into @ResultTable Values (@item)
			set @List = SUBSTRING(@List, @separatorPosition+1,LEN(@List))
		END
		ELSE
			return

	END

RETURN
END

