create database controle_academico;

use controle_academico;

create table aluno(
ra int not null,
nome varchar(50) not null,
constraint pk_aluno primary key (ra)
);

create table disciplina(
sigla varchar(3) not null,
nome varchar(30) not null,
carga_horaria int not null,
constraint pk_disciplina primary key (sigla)
);

create table matricula(
ra int not null,
sigla varchar(3) not null,
dataAno int not null,
dataSemestre int not null,
nota1 float,
nota2 float,
notaSub float,
media float,
situacao varchar(20),
frequencia float,
faltas int,
foreign key (ra) references aluno(ra),
foreign key (sigla) references disciplina(sigla),
constraint pk_matricula primary key(ra, sigla, dataAno, dataSemestre)
);

create trigger calculoMedia on matricula
after update as if update(nota2)
begin
	declare
	@nota1 decimal(10,2),
	@nota2 decimal(10,2),
	@media decimal(10,2),
	@ano int,
	@semestre int,
	@ra int,
	@sigla varchar(3)

	select @ano = dataAno, @semestre = dataSemestre, @nota1 = nota1, @nota2 = nota2, @sigla = sigla, @ra = ra from inserted
	select @media = (@nota1 + @nota2) / 2
	update matricula set media = @media
	where ra = @ra and sigla = @sigla and dataAno = @ano and dataSemestre = @semestre
end

create trigger calculoFreq
on matricula
after update
as 
if UPDATE(faltas)
begin
	declare
		@falta float,
		@ra int,
		@sigla varchar(3), 
		@cargaHr int,
		@freq decimal(10,2),
		@ano int,
		@semestre int
	
	select @falta = faltas, @ano = dataAno, @semestre = dataSemestre, @sigla = sigla, @ra = ra from inserted

	select @cargaHr = carga_horaria
	from disciplina
	where sigla = @sigla

	select @freq = (1-(@falta/@cargaHr)) * 100

	update matricula set frequencia = @freq
	where ra = @ra and sigla = @sigla and dataAno = @ano and dataSemestre = @semestre
end


create trigger notaSub on matricula
after update
as
if UPDATE(notaSub)
begin
	declare
	@nota1 float,
	@nota2 float,
	@notaSub float,
	@media float,
	@ra int,
	@sigla varchar(3),
	@ano int,
	@semestre int

	select @ano = dataAno, @semestre = dataSemestre,@notaSub = notaSub, @nota1 = nota1, @nota2 = nota2, @sigla = sigla, @ra = ra from inserted

	if(@nota1 > @nota2)
		begin
		select @media = (@nota1 + @notaSub)/2
		update matricula set media = @media
		where ra = @ra and sigla = @sigla and dataAno = @ano and dataSemestre = @semestre
		end
	else
		begin
		select @media = (@nota2 + @notaSub)/2
		update matricula set media = @media
		where ra = @ra and sigla = @sigla and dataAno = @ano and dataSemestre = @semestre
		end
end

create trigger setSituacao on matricula
after update as if update(media) or update(frequencia)
begin
	declare
	@media float,
	@ra int,
	@sigla varchar(3),
	@freq float,
	@notaSub float

	select @notaSub = notaSub, @ra = ra, @sigla = sigla, @freq = frequencia, @media = media from inserted

	 if(@freq < 75)
	begin
		update matricula set situacao = 'REPROVADO POR FALTA'
		where ra = @ra and sigla = @sigla
	end
	else if(@media >= 5)
		begin
		update matricula set situacao = 'APROVADO'
		where ra = @ra and sigla = @sigla
	end
	else if(@media < 5 and @notaSub <> null)
	begin
		update matricula set situacao = 'REPROVADO POR NOTA'
		where ra = @ra and sigla = @sigla
	end
end

create trigger rematricula on matricula
after update as if (select situacao from inserted) <> 'APROVADO'
begin
	declare
	@ra int, @sigla varchar(3), @situacao varchar(20), @notaSub float, @freq float
	
	select @ra = ra, @sigla = sigla, @freq = frequencia, @situacao = situacao from inserted

	insert into matricula(ra,sigla, dataAno, dataSemestre)
	values(@ra, @sigla, 2022,1)
end

insert into aluno(ra, nome)
values(1, 'Aluno 1'),(2, 'Aluno 2'),(3, 'Aluno 3'),(4, 'Aluno 4'),(5, 'Aluno 5'),(6, 'Aluno 6'),(7, 'Aluno 7'),(8, 'Aluno 8'),(9, 'Aluno 9'),(10, 'Aluno 10')

insert into disciplina(sigla, nome, carga_horaria)
values('ED', 'ESTRUTURA DE DADOS', 100),('CA', 'CALCULO', 150),('PT', 'PORTUGUES', 200),('LGP', 'LINGUAGEM DE PROGRAMAÇÃO', 70),('JS', 'JAVASCRIPT', 120),('LC#', 'LINGUAGEM C#', 150),('LC+', 'LINGUAGEM C++', 135),('HTM', 'LINGUAGEM HTML', 90),('CSS', ' LINGUAGEM CSS', 50),('GIT', 'VERSIONAMENTO GIT', 135)

insert into matricula(ra, sigla, dataAno, dataSemestre)
values(1,'ED', 2021,2),(2,'CA', 2021,2),(3,'ED', 2021,2),(4,'PT', 2021,2),(5,'LGP', 2021,2),(6,'JS', 2021,2),(7,'LC+', 2021,2),(8,'LC#', 2021,2),(9,'CSS', 2021,2),(10,'HTM', 2021,2)

update matricula
set nota2 = 10, faltas = 100
where ra = 1 and sigla = 'ED' and dataAno = 2021

update matricula
set notaSub = 10
where ra = 1 and sigla = 'ED' and dataAno = 2021 and dataSemestre = 2

--alunos matriculas
select a.ra 'RA Aluno', a.nome 'Nome Aluno', d.nome 'Disciplina',  m.nota1 'Nota 1', m.nota2 'Nota 2', m.notaSub 'Nota Sub', m.media 'Media', m.frequencia 'Freq %', m.situacao 'Situação Final'
from aluno a, matricula m, disciplina d
where m.sigla = 'LC+' and a.ra = m.ra and m.sigla = d.sigla and m.dataAno = 2021

--aluno individual
select a.ra 'RA Aluno', a.nome 'Nome Aluno', d.nome 'Disciplina',  m.nota1 'Nota 1', m.nota2 'Nota 2', m.notaSub 'Nota Sub', m.media 'Media', m.frequencia 'Freq %', m.situacao 'Situação Final'
from aluno a, matricula m, disciplina d
where  a.ra = 4 and a.ra = m.ra and m.sigla = d.sigla and m.dataAno = 2022

--alunos reprovados
select a.ra 'RA Aluno', a.nome 'Nome Aluno', d.nome 'Disciplina',  m.nota1 'Nota 1', m.nota2 'Nota 2', m.notaSub 'Nota Sub', m.media 'Media', m.frequencia 'Freq %', m.situacao 'Situação Final'
from aluno a, matricula m, disciplina d
where m.situacao <> 'APROVADO' and a.ra = m.ra and m.sigla = d.sigla and m.dataAno = 2022

--todos os alunos
select a.ra 'RA aluno', a.nome 'Nome aluno', m.sigla 'Sigla disciplina', d.nome 'Nome Disciplina',m.nota1 'Nota 1° Bimestre', m.nota2 'Nota 2° Bimestre' , m.media 'Media final', m.frequencia 'Frequencia final', m.situacao 'Situação final'
from aluno a, matricula m, disciplina d
where a.ra = m.ra and m.sigla = d.sigla and m.dataAno = 2021

select * from matricula