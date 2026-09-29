-- 1. BAZA DE DATE
CREATE DATABASE Tema2;
GO

USE Tema2;
GO

ALTER DATABASE Tema2
ADD FILEGROUP FG_Index;
GO

ALTER DATABASE Tema2
ADD FILE
(
    NAME='Tema_Index',
    FILENAME='/var/opt/mssql/data/Tema2_Index.ndf',
    SIZE=50MB,
    FILEGROWTH=50MB
)
TO FILEGROUP FG_Index;
GO

SELECT
    name,
    physical_name,
    type_desc,
    FILEGROUP_NAME(data_space_id) AS FileGroupName
FROM sys.database_files;
GO

-- 2. SCHEME
CREATE SCHEMA app;
GO

CREATE SCHEMA report;
GO
-- 3. TABELE

CREATE TABLE app.Sediu
(
    SediuId INT IDENTITY(1,1) NOT NULL,
    Nume VARCHAR(100) NOT NULL,
    Oras VARCHAR(50) NOT NULL,
    Adresa VARCHAR(200) NULL,
    CONSTRAINT PK_Sediu PRIMARY KEY (SediuId),
    CONSTRAINT UQ_Sediu_Nume UNIQUE (Nume)
);
GO

CREATE TABLE app.Departament
(
    DepartamentId INT IDENTITY(1,1) NOT NULL,
    SediuId INT NOT NULL,
    NumeDepartament VARCHAR(100) NOT NULL,
    CONSTRAINT PK_Departament PRIMARY KEY (DepartamentId),
    CONSTRAINT FK_Departament_Sediu FOREIGN KEY (SediuId) REFERENCES app.Sediu(SediuId),
    CONSTRAINT UQ_Departament UNIQUE (SediuId,NumeDepartament)
);
GO

CREATE TABLE app.TipAbsenta
(
    TipAbsentaId INT IDENTITY(1,1) NOT NULL,
    Denumire VARCHAR(50) NOT NULL,
    NecesitaAprobare BIT NOT NULL DEFAULT(1),
    CONSTRAINT PK_TipAbsenta PRIMARY KEY(TipAbsentaId),
    CONSTRAINT UQ_TipAbsenta UNIQUE(Denumire)
);
GO

CREATE TABLE app.Proiect
(
    ProiectId INT IDENTITY(1,1) NOT NULL,
    SediuId INT NOT NULL,
    CodProiect VARCHAR(20) NOT NULL,
    NumeProiect VARCHAR(150) NOT NULL,
    Client VARCHAR(100) NOT NULL,
    CONSTRAINT PK_Proiect PRIMARY KEY(ProiectId),
    CONSTRAINT FK_Proiect_Sediu FOREIGN KEY(SediuId) REFERENCES app.Sediu(SediuId),
    CONSTRAINT UQ_Proiect_Cod UNIQUE(CodProiect)
);
GO

CREATE TABLE app.Angajat
(
    AngajatId INT IDENTITY(1,1) NOT NULL,
    DepartamentId INT NOT NULL,
    ManagerId INT NULL,
    Nume VARCHAR(50) NOT NULL,
    Prenume VARCHAR(50) NOT NULL,
    CNP CHAR(13) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    Telefon VARCHAR(20) NULL,
    Functie VARCHAR(50) NOT NULL,
    DataAngajarii DATE NOT NULL DEFAULT(CAST(GETDATE() AS DATE)),
    Salariu DECIMAL(10,2) NOT NULL,
    DateContract NVARCHAR(MAX) NULL,
    CONSTRAINT PK_Angajat PRIMARY KEY(AngajatId),
    CONSTRAINT FK_Angajat_Departament FOREIGN KEY(DepartamentId) REFERENCES app.Departament(DepartamentId),
    CONSTRAINT FK_Angajat_Manager FOREIGN KEY(ManagerId) REFERENCES app.Angajat(AngajatId),
    CONSTRAINT UQ_Angajat_CNP UNIQUE(CNP),
    CONSTRAINT UQ_Angajat_Email UNIQUE(Email),
    CONSTRAINT CK_Angajat_Salariu CHECK(Salariu>0),
    CONSTRAINT CK_Angajat_JSON CHECK(DateContract IS NULL OR ISJSON(DateContract)=1)
);
GO

CREATE TABLE app.Pontaj
(
    PontajId INT IDENTITY(1,1) NOT NULL,
    AngajatId INT NOT NULL,
    SaptamanaStart DATE NOT NULL,
    SaptamanaSfarsit DATE NOT NULL,
    OreLucrateTotal DECIMAL(5,2) NOT NULL DEFAULT(0),
    Status VARCHAR(20) NOT NULL DEFAULT('Draft'),
    AprobatDe INT NULL,
    DataAprobare DATETIME NULL,
    CONSTRAINT PK_Pontaj PRIMARY KEY(PontajId),
    CONSTRAINT FK_Pontaj_Angajat FOREIGN KEY(AngajatId) REFERENCES app.Angajat(AngajatId),
    CONSTRAINT FK_Pontaj_AprobatDe FOREIGN KEY(AprobatDe) REFERENCES app.Angajat(AngajatId),
    CONSTRAINT UQ_Pontaj_Angajat_Saptamana UNIQUE(AngajatId,SaptamanaStart),
    CONSTRAINT CK_Pontaj_Status CHECK (Status IN( 'Draft', 'Trimis',   'Aprobat', 'Respins' ) ),
    CONSTRAINT CK_Pontaj_Perioada CHECK( SaptamanaStart <= SaptamanaSfarsit )
    );
GO

CREATE TABLE app.PontajZi
(
    PontajZiId INT IDENTITY(1,1) NOT NULL,
    PontajId INT NOT NULL,
    Data DATE NOT NULL,
    TipZi VARCHAR(20) NOT NULL,
    TipAbsentaId INT NULL,
    OreZi DECIMAL(4,2) NOT NULL DEFAULT(0),
    CONSTRAINT PK_PontajZi  PRIMARY KEY(PontajZiId),
    CONSTRAINT FK_PontajZi_Pontaj FOREIGN KEY(PontajId) REFERENCES app.Pontaj(PontajId),
    CONSTRAINT FK_PontajZi_TipAbsenta FOREIGN KEY(TipAbsentaId) REFERENCES app.TipAbsenta(TipAbsentaId),
    CONSTRAINT UQ_PontajZi   UNIQUE(PontajId, Data),
    CONSTRAINT CK_PontajZi_TipZi CHECK ( TipZi IN ('Lucrat','Absenta')  ),
    CONSTRAINT CK_PontajZi_Coerenta CHECK ((TipZi='Absenta' AND TipAbsentaId IS NOT NULL AND OreZi=0)
   OR (TipZi='Lucrat' AND TipAbsentaId IS NULL AND OreZi>=0 AND OreZi<=24))
);
GO

CREATE TABLE app.DetaliuPontaj
(
    DetaliuId INT IDENTITY(1,1) NOT NULL,
    PontajZiId INT NOT NULL,
    ProiectId INT NOT NULL,
    Ore DECIMAL(4,2) NOT NULL,
    DetaliiActivitate NVARCHAR(MAX) NULL,
    CONSTRAINT PK_DetaliuPontaj PRIMARY KEY(DetaliuId),
    CONSTRAINT FK_DetaliuPontaj_PontajZi FOREIGN KEY(PontajZiId) REFERENCES app.PontajZi(PontajZiId),
    CONSTRAINT FK_DetaliuPontaj_Proiect FOREIGN KEY(ProiectId)REFERENCES app.Proiect(ProiectId),
    CONSTRAINT CK_DetaliuPontaj_Ore CHECK ( Ore>0  AND Ore<=24),
    CONSTRAINT CK_DetaliuPontaj_JSON CHECK( DetaliiActivitate IS NULL OR ISJSON(DetaliiActivitate)=1   )
);
GO

 --  4. INDEXURI SUPLIMENTARE 
  
-- Index pe status, folosit pentru filtrarea rapida a pontajelor dupa stare
CREATE NONCLUSTERED INDEX IX_Pontaj_Status
ON app.Pontaj(Status);
GO
 
-- Index filtrat: indexeaza doar pontajele cu Status = 'Aprobat'
CREATE NONCLUSTERED INDEX IX_Pontaj_Aprobat
ON app.Pontaj(SaptamanaStart)
WHERE Status = 'Aprobat';
GO
 
-- Cauta angajati dupa nume si prenume
CREATE NONCLUSTERED INDEX IX_Angajat_NumePrenume
ON app.Angajat(Nume, Prenume);
GO
 
-- Cauta dupa numele proiectului
CREATE NONCLUSTERED INDEX IX_Proiect_Nume
ON app.Proiect(NumeProiect);
GO
 
-- Index pe data din pontaj, pentru interogari pe zi
CREATE NONCLUSTERED INDEX IX_PontajZi_Data
ON app.PontajZi(Data);
GO
 
-- Index dupa PontajZiId, pentru agregarea rapida a orelor pe zi
CREATE NONCLUSTERED INDEX IX_DetaliuPontaj_PontajZi
ON app.DetaliuPontaj(PontajZiId);
GO
 
-- Index dupa ProiectId, pentru cautarea numarului de ore pe fiecare proiect
CREATE NONCLUSTERED INDEX IX_DetaliuPontaj_Proiect
ON app.DetaliuPontaj(ProiectId);
GO
 
   --5. TRIGGERE
   
-- Verifica daca data din PontajZi apartine saptamanii aferente pontajului
CREATE TRIGGER app.trg_PontajZi_ValidareData
ON app.PontajZi
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS
    (
        SELECT *
        FROM inserted i
        JOIN app.Pontaj p
            ON i.PontajId = p.PontajId
        WHERE i.Data NOT BETWEEN p.SaptamanaStart AND p.SaptamanaSfarsit
    )
    BEGIN
        PRINT 'Data nu apartine saptamanii!';
        ROLLBACK TRANSACTION;
    END
END;
GO
 
-- Recalculeaza automat PontajZi.OreZi si Pontaj.OreLucrateTotal
-- de fiecare data cand se modifica app.DetaliuPontaj (INSERT/UPDATE/DELETE)
CREATE TRIGGER app.trg_DetaliuPontaj
ON app.DetaliuPontaj
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Recalculează OreZi pentru zilele afectate
    UPDATE pz
    SET OreZi = ISNULL(
    (
        SELECT SUM(dp.Ore)
        FROM app.DetaliuPontaj dp
        WHERE dp.PontajZiId = pz.PontajZiId
    ), 0)
    FROM app.PontajZi pz
    INNER JOIN
    (
        SELECT PontajZiId FROM inserted
        UNION
        SELECT PontajZiId FROM deleted
    ) za
        ON pz.PontajZiId = za.PontajZiId;

    -- Recalculează totalul orelor lucrate
    UPDATE p
    SET OreLucrateTotal = ISNULL(
    (
        SELECT SUM(pz.OreZi)
        FROM app.PontajZi pz
        WHERE pz.PontajId = p.PontajId
    ), 0)
    FROM app.Pontaj p
    INNER JOIN
    (
        SELECT DISTINCT pz.PontajId
        FROM app.PontajZi pz
        INNER JOIN
        (
            SELECT PontajZiId FROM inserted
            UNION
            SELECT PontajZiId FROM deleted
        ) z
            ON pz.PontajZiId = z.PontajZiId
    ) pa
        ON p.PontajId = pa.PontajId;
END;
GO
   --6. VIEW-URI  
-- View simplu: rezumat al pontajului saptamanal pentru fiecare angajat
CREATE VIEW report.vw_Pontaj
AS
SELECT
    p.PontajId,
    a.AngajatId,
    a.Nume + ' ' + a.Prenume AS NumeComplet,
    p.SaptamanaStart,
    p.SaptamanaSfarsit,
    p.OreLucrateTotal,
    p.Status,
    mgr.Nume + ' ' + mgr.Prenume AS AprobatDeNume
FROM app.Pontaj p
JOIN app.Angajat a
    ON a.AngajatId = p.AngajatId
LEFT JOIN app.Angajat mgr
    ON mgr.AngajatId = p.AprobatDe;
GO
 
-- View simplu: pontajul detaliat pe zile pentru fiecare angajat
CREATE VIEW report.vw_PontajZi
AS
SELECT
    p.PontajId,
    a.AngajatId,
    a.Nume + ' ' + a.Prenume AS NumeComplet,
    pz.PontajZiId,
    pz.Data,
    DATENAME(WEEKDAY, pz.Data) AS ZiuaSaptamanii,
    pz.TipZi,
    ta.Denumire AS TipAbsenta,
    pz.OreZi
FROM app.PontajZi pz
JOIN app.Pontaj p
    ON p.PontajId = pz.PontajId
JOIN app.Angajat a
    ON a.AngajatId = p.AngajatId
LEFT JOIN app.TipAbsenta ta
    ON ta.TipAbsentaId = pz.TipAbsentaId;
GO
 
-- MATERIALIZED VIEW (indexed view in SQL Server):
-- calculeaza numarul de inregistrari si totalul orelor lucrate pe fiecare proiect.
-- Pentru a fi materializat, view-ul trebuie creat WITH SCHEMABINDING si sa aiba un index clustered unic.
CREATE VIEW report.mv_OrePeProiect
WITH SCHEMABINDING
AS
SELECT
    dp.ProiectId,
    COUNT_BIG(*) AS NrInregistrari,
    SUM(dp.Ore) AS TotalOre
FROM app.DetaliuPontaj dp
GROUP BY dp.ProiectId;
GO
 
-- Indexul clustered unic transforma view-ul intr-un materialized (indexed) view
CREATE UNIQUE CLUSTERED INDEX IX_mv_OrePeProiect
ON report.mv_OrePeProiect(ProiectId);
GO
 
 --  7. VERIFICARE CREARE VIEW-URI

-- Lista tuturor view-urilor create in schema 'report'
SELECT *
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'report';
GO
 
-- Verificare continut view simplu (rezumat pontaj)
SELECT *
FROM report.vw_Pontaj;
GO
 
-- Verificare continut view simplu (detaliu pe zile)
SELECT *
FROM report.vw_PontajZi;
GO
 
-- Verificare continut materialized view (ore pe proiect)
SELECT *
FROM report.mv_OrePeProiect;
GO
 
 --  8. DATE DE TEST
 
INSERT INTO app.Sediu (Nume, Oras, Adresa)
VALUES
('Endava Bucuresti', 'Bucuresti', 'Str. Dimitrie Pompeiu 5-7'),
('Endava Cluj', 'Cluj-Napoca', 'Str. Henri Barbusse 44');
GO
 
INSERT INTO app.Departament (SediuId, NumeDepartament)
VALUES
(1, 'Software Development'),
(1, 'Quality Assurance'),
(1, 'HR'),
(1, 'Finance'),
(1, 'IT Support'),
(2, 'Software Development'),
(2, 'Quality Assurance'),
(2, 'HR'),
(2, 'Finance'),
(2, 'IT Support');
GO
 
INSERT INTO app.TipAbsenta (Denumire, NecesitaAprobare)
VALUES
('Concediu Odihna', 1),
('Concediu Medical', 0),
('Zi libera legala', 0),
('Delegatie', 1);
GO
 
INSERT INTO app.Proiect (SediuId, CodProiect, NumeProiect, Client)
VALUES
(1, 'BUC001', 'Digital Banking Platform', 'ING'),
(1, 'BUC002', 'Retail Automation', 'Carrefour'),
(1, 'BUC003', 'Telecom CRM Upgrade', 'Vodafone'),
(1, 'BUC004', 'Insurance Claims Portal', 'Allianz'),
(1, 'BUC005', 'Healthcare Mobile App', 'Regina Maria'),
(2, 'CLJ001', 'E-commerce Engine', 'Emag'),
(2, 'CLJ002', 'Transport Optimization', 'CFR'),
(2, 'CLJ003', 'Smart City Dashboard', 'Primaria Cluj'),
(2, 'CLJ004', 'Energy Monitoring System', 'Electrica'),
(2, 'CLJ005', 'Fintech Fraud Detection', 'Revolut');
GO
 
INSERT INTO app.Angajat
    (DepartamentId, ManagerId, Nume, Prenume, CNP, Email, Telefon, Functie, Salariu, DateContract)
VALUES
(1, NULL, 'Popescu',   'Andrei',     '1980101223456', 'andrei.popescu@endava.com',    '0722000001', 'Software Engineer',        12000, '{"tip":"full-time"}'),
(1, 1,    'Ionescu',   'Maria',      '2890506123456', 'maria.ionescu@endava.com',     '0722000002', 'Senior Software Engineer', 16000, '{"tip":"full-time"}'),
(2, NULL, 'Georgescu', 'Raluca',     '2910301123456', 'raluca.georgescu@endava.com',  '0722000003', 'QA Engineer',              11000, '{"tip":"full-time"}'),
(3, NULL, 'Dumitru',   'Alexandra',  '2930202123456', 'alexandra.dumitru@endava.com', '0722000004', 'HR Specialist',             9000, '{"tip":"full-time"}'),
(4, NULL, 'Stan',      'Mihai',      '1950405123456', 'mihai.stan@endava.com',        '0722000005', 'Financial Analyst',        10000, '{"tip":"full-time"}');
GO
 
INSERT INTO app.Pontaj (AngajatId, SaptamanaStart, SaptamanaSfarsit, Status)
VALUES
(1, '2026-06-01', '2026-06-07', 'Draft'),
(2, '2026-06-01', '2026-06-07', 'Trimis'),
(3, '2026-06-01', '2026-06-07', 'Aprobat');
GO
 
-- Andrei
INSERT INTO app.PontajZi (PontajId, Data, TipZi, TipAbsentaId, OreZi)
VALUES
(1, '2026-06-01', 'Lucrat',  NULL, 0),
(1, '2026-06-02', 'Lucrat',  NULL, 0),
(1, '2026-06-03', 'Absenta', 1,    0),
(1, '2026-06-04', 'Absenta', 1,    0),
(1, '2026-06-05', 'Absenta', 1,    0);
GO
 
-- Maria
INSERT INTO app.PontajZi (PontajId, Data, TipZi, TipAbsentaId, OreZi)
VALUES
(2, '2026-06-01', 'Lucrat', NULL, 0),
(2, '2026-06-02', 'Lucrat', NULL, 0),
(2, '2026-06-03', 'Lucrat', NULL, 0),
(2, '2026-06-04', 'Lucrat', NULL, 0),
(2, '2026-06-05', 'Lucrat', NULL, 0);
GO
 
-- Raluca
INSERT INTO app.PontajZi (PontajId, Data, TipZi, TipAbsentaId, OreZi)
VALUES
(3, '2026-06-01', 'Lucrat',  NULL, 0),
(3, '2026-06-02', 'Lucrat',  NULL, 0),
(3, '2026-06-03', 'Absenta', 2,    0),
(3, '2026-06-04', 'Absenta', 2,    0),
(3, '2026-06-05', 'Lucrat',  NULL, 0);
GO
 
INSERT INTO app.DetaliuPontaj (PontajZiId, ProiectId, Ore, DetaliiActivitate)
VALUES
-- Andrei
(1, 1, 6, '{"activitate":"dezvoltare"}'),
(1, 2, 2, '{"activitate":"code review"}'),
(2, 1, 8, '{"activitate":"dezvoltare"}'),
-- Maria
(6, 1, 8, '{"activitate":"dezvoltare"}'),
(7, 1, 8, '{"activitate":"dezvoltare"}'),
(8, 2, 8, '{"activitate":"analiza"}'),
(9, 2, 8, '{"activitate":"implementare"}'),
(10, 1, 8, '{"activitate":"bug fixing"}'),
-- Raluca
(11, 3, 8, '{"activitate":"testare"}'),
(12, 3, 8, '{"activitate":"testare"}'),
(15, 3, 8, '{"activitate":"testare"}');
GO
 
  -- 9. TESTARE TRIGGER (recalculare automata a orelor)
 
-- Stare initiala: orele pe ziua 1 (dupa inserarea din DetaliuPontaj)
SELECT PontajZiId, OreZi
FROM app.PontajZi
WHERE PontajZiId = 1;
GO
 
-- Stare initiala: totalul orelor lucrate pe pontajul 1
SELECT PontajId, OreLucrateTotal
FROM app.Pontaj
WHERE PontajId = 1;
GO
 
-- INSERT: adaugam o noua activitate pe ziua 1 -> trigger-ul recalculeaza automat
INSERT INTO app.DetaliuPontaj (PontajZiId, ProiectId, Ore, DetaliiActivitate)
VALUES (1, 3, 1, '{"activitate":"sedinta"}');
GO
 
-- Verificare dupa INSERT: OreZi trebuie sa reflecte noua activitate
SELECT PontajZiId, OreZi
FROM app.PontajZi
WHERE PontajZiId = 1;
GO
 
-- Verificare dupa INSERT: OreLucrateTotal trebuie recalculat
SELECT PontajId, OreLucrateTotal
FROM app.Pontaj
WHERE PontajId = 1;
GO
 
-- UPDATE: modificam orele unei activitati existente -> trigger recalculeaza
UPDATE app.DetaliuPontaj
SET Ore = 3
WHERE PontajZiId = 1
  AND ProiectId = 2;
GO
 
-- Verificare dupa UPDATE: OreZi
SELECT PontajZiId, OreZi
FROM app.PontajZi
WHERE PontajZiId = 1;
GO
 
-- Verificare dupa UPDATE: OreLucrateTotal
SELECT PontajId, OreLucrateTotal
FROM app.Pontaj
WHERE PontajId = 1;
GO
 
-- DELETE: stergem o activitate -> trigger recalculeaza din nou
DELETE FROM app.DetaliuPontaj
WHERE PontajZiId = 1
  AND ProiectId = 3;
GO
 
-- Verificare dupa DELETE: OreZi
SELECT PontajZiId, OreZi
FROM app.PontajZi
WHERE PontajZiId = 1;
GO
 
-- Verificare dupa DELETE: OreLucrateTotal
SELECT PontajId, OreLucrateTotal
FROM app.Pontaj
WHERE PontajId = 1;
GO
 
-- Verificare finala d: compara OreLucrateTotal stocat
--cu suma reala a OreZi din PontajZi (diferenta trebuie sa fie 0)
SELECT
    p.PontajId,
    p.OreLucrateTotal,
    ISNULL(SUM(pz.OreZi), 0) AS SumaDinZile,
    p.OreLucrateTotal - ISNULL(SUM(pz.OreZi), 0) AS Diferenta
FROM app.Pontaj p
LEFT JOIN app.PontajZi pz
    ON p.PontajId = pz.PontajId
GROUP BY
    p.PontajId,
    p.OreLucrateTotal
ORDER BY
    p.PontajId;
GO
 
 --  10. INTEROGARI
-- Situatia saptamanala (zi cu zi) pentru pontajul cu PontajId = 1
SELECT
    Data,
    ZiuaSaptamanii,
    TipZi,
    TipAbsenta,
    OreZi
FROM report.vw_PontajZi
WHERE PontajId = 1
ORDER BY Data;
GO
 
-- Total ore lucrate pe angajat (GROUP BY)
SELECT
    p.AngajatId,
    SUM(p.OreLucrateTotal) AS TotalOreLucrate
FROM app.Pontaj p
GROUP BY
    p.AngajatId
ORDER BY
    p.AngajatId;
GO
 
-- Numar de zile lucrate / absente per angajat (GROUP BY pe doua coloane)
SELECT
    p.AngajatId,
    pz.TipZi,
    COUNT(*) AS NrZile
FROM app.PontajZi pz
JOIN app.Pontaj p
    ON pz.PontajId = p.PontajId
GROUP BY
    p.AngajatId,
    pz.TipZi
ORDER BY
    p.AngajatId,
    pz.TipZi;
GO
 
-- LEFT JOIN: toate zilele de pontaj, cu tipul de absenta daca exista
-- (angajatii care nu au avut absente vor avea TipAbsenta = NULL)
SELECT
    pz.PontajZiId,
    p.AngajatId,
    pz.Data,
    pz.TipZi,
    ta.Denumire AS TipAbsenta,
    pz.OreZi
FROM app.PontajZi pz
JOIN app.Pontaj p
    ON p.PontajId = pz.PontajId
LEFT JOIN app.TipAbsenta ta
    ON ta.TipAbsentaId = pz.TipAbsentaId
ORDER BY
    p.AngajatId,
    pz.Data;
GO
 
-- Functie analitica (AVG() OVER PARTITION BY, diferita de ROW_NUMBER):
-- calculeaza media orelor lucrate pe zi pentru fiecare angajat,
-- afisata alaturi de fiecare zi lucrata in parte
SELECT
    p.AngajatId,
    pz.Data,
    pz.OreZi,
    AVG(pz.OreZi) OVER (PARTITION BY p.AngajatId) AS MedieOrePeZi
FROM app.PontajZi pz
JOIN app.Pontaj p
    ON p.PontajId = pz.PontajId
WHERE pz.TipZi = 'Lucrat'
ORDER BY
    p.AngajatId,
    pz.Data;
GO
 
-- JSON: afiseaza datele contractuale ale fiecarui angajat,
-- extragand campul "tip" din coloana JSON DateContract
SELECT
    AngajatId,
    Nume,
    Prenume,
    DateContract,
    JSON_VALUE(DateContract, '$.tip') AS TipContract
FROM app.Angajat
ORDER BY
    AngajatId;
GO
 
-- JSON: afiseaza activitatile desfasurate de fiecare angajat, proiectul
-- pe care a lucrat si numarul de ore, extragand activitatea din coloana JSON
SELECT
    dp.DetaliuId,
    a.Nume + ' ' + a.Prenume AS NumeComplet,
    pz.Data,
    pr.NumeProiect,
    dp.Ore,
    JSON_VALUE(dp.DetaliiActivitate, '$.activitate') AS Activitate
FROM app.DetaliuPontaj dp
JOIN app.PontajZi pz
    ON dp.PontajZiId = pz.PontajZiId
JOIN app.Pontaj p
    ON pz.PontajId = p.PontajId
JOIN app.Angajat a
    ON a.AngajatId = p.AngajatId
JOIN app.Proiect pr
    ON pr.ProiectId = dp.ProiectId
ORDER BY
    a.AngajatId,
    pz.Data;
GO
 
-- Verificare utilizare index IX_Pontaj_Aprobat: filtrare rapida dupa Status
SELECT *
FROM app.Pontaj
WHERE Status = 'Aprobat';
GO
 
-- Verificare utilizare index IX_PontajZi_Data: filtrare rapida dupa Data
SELECT *
FROM app.PontajZi
WHERE Data = '2026-06-02';
GO
 
-- Verificare utilizare index IX_Angajat_NumePrenume: cautare dupa nume/prenume
SELECT *
FROM app.Angajat
WHERE Nume = 'Popescu'
  AND Prenume = 'Andrei';
GO
 
-- Verificare utilizare index IX_Proiect_Nume: cautare dupa numele proiectului
SELECT *
FROM app.Proiect
WHERE NumeProiect = 'Digital Banking Platform';
GO