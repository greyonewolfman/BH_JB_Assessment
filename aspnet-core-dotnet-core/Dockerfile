#Use the official .NET Core SDK image as the base image
FROM mcr.microsoft.com/dotnet/core/sdk:2.2 AS build
WORKDIR /app

#Copy the .CSproj and restore as distinct layers
COPY *.csproj ./
RUN dotnet restore

#Copy the remain source code and build the application 
COPY . ./
RUN dotnet publish -c Release -o out

#Build the image
FROM mcr.microsoft.com/dotnet/core/aspnet:2.2
WORKDIR /app
COPY --from=build /app/out .

#Entry point when the container starts
ENTRYPOINT ["dotnet", "aspnet-core-dotnet-core.dll"]