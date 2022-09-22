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
	@ra int,
	@freq float,
	@sigla varchar(3)

	select @nota1 = nota1, @nota2 = nota2, @sigla = sigla, @freq= frequencia, @ra = ra from inserted
	select @media = (@nota1 + @nota2) / 2
	update matricula set media = @media
	where ra = @ra and sigla = @sigla
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
		@freq decimal(10,2)
	
	select @falta = faltas, @sigla = sigla,  @ra = ra from inserted

	select @cargaHr = carga_horaria
	from disciplina
	where sigla = @sigla

	select @freq = (1-(@falta/@cargaHr)) * 100

	update matricula set frequencia = @freq
	where ra = @ra and sigla = @sigla;
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
	@sigla varchar(11)

	select @nota1 = nota1, @nota2 = nota2, @media = media, @notaSub = notaSub, @sigla = sigla, @ra = ra from inserted

	if(@nota1 > @nota2)
		begin
		select @media = (@nota1 + @notaSub)/2
		update matricula set media = @media
		where ra = @ra and sigla = @sigla
		end
	else
		begin
		select @media = (@nota2 + @notaSub)/2
		update matricula set media = @media
		where ra = @ra and sigla = @sigla
		end
end

create trigger setSituacao on matricula
after update as if update(media) or update(frequencia)
begin
	declare
	@media float,
	@ra int,
	@sigla varchar(3),
	@freq float

	select @ra = ra, @sigla = sigla, @freq = frequencia, @media = media from inserted

	if(@media >= 5 and @freq > 75)
		begin
		update matricula set situacao = 'APROVADO'
		where ra = @ra and sigla = @sigla
	end
	else if(@media < 5)
	begin
		update matricula set situacao = 'REPROVADO POR NOTA'
		where ra = @ra and sigla = @sigla
	end
	else if(@freq < 75)
	begin
		update matricula set situacao = 'REPROVADO POR FALTA'
		where ra = @ra and sigla = @sigla
	end
end

create trigger rematricula on matricula
after update as if update(media) or update(frequencia)
begin
	declare
	@ra int, @sigla varchar(3), @situacao varchar(20), @notaSub float, @freq float
	
	select @ra = ra, @sigla = sigla, @freq = frequencia, @situacao = situacao from inserted

	if(@situacao <> 'APROVADO')
		begin
		insert into matricula(ra,sigla, dataAno, dataSemestre)
		values(@ra, @sigla, 2022,1)
		end
end

insert into aluno(ra, nome)
values(1, 'Aluno 1'),(2, 'Aluno 2'),(3, 'Aluno 3'),(4, 'Aluno 4'),(5, 'Aluno 5'),(6, 'Aluno 6'),(7, 'Aluno 7'),(8, 'Aluno 8'),(9, 'Aluno 9'),(10, 'Aluno 10')

insert into disciplina(sigla, nome, carga_horaria)
values('ED', 'ESTRUTURA DE DADOS', 100),('CA', 'CALCULO', 150),('PT', 'PORTUGUES', 200),('LGP', 'LINGUAGEM DE PROGRAMAÇÃO', 70),('JS', 'JAVASCRIPT', 120),('LC#', 'LINGUAGEM C#', 150),('LC+', 'LINGUAGEM C++', 135),('HTM', 'LINGUAGEM HTML', 90),('CSS', ' LINGUAGEM CSS', 50),('GIT', 'VERSIONAMENTO GIT', 135)

insert into matricula(ra, sigla, dataAno, dataSemestre)
values(1,'ED', 2021,2),(2,'CA', 2021,2),(3,'ED', 2021,2),(4,'PT', 2021,2),(5,'LGP', 2021,2),(6,'JS', 2021,2),(7,'LC+', 2021,2),(8,'LC#', 2021,2),(9,'CSS', 2021,2),(10,'HTM', 2021,2)

update matricula
set nota1 =10, nota2 = 10, faltas = 1
where ra = 5 and sigla = 'LGP' and dataAno = 2021

update matricula
set notaSub = 5
where ra = 4 and sigla = 'PT' and dataAno = 2021

--alunos matriculas
select a.ra 'RA Aluno', a.nome 'Nome Aluno', d.nome 'Disciplina',  m.nota1 'Nota 1', m.nota2 'Nota 2', m.notaSub 'Nota Sub', m.media 'Media', m.frequencia 'Freq %', m.situacao 'Situação Final'
from aluno a, matricula m, disciplina d
where m.sigla = 'ED' and a.ra = m.ra and m.sigla = d.sigla and m.dataAno = 2021

--aluno individual
select a.ra 'RA Aluno', a.nome 'Nome Aluno', d.nome 'Disciplina',  m.nota1 'Nota 1', m.nota2 'Nota 2', m.notaSub 'Nota Sub', m.media 'Media', m.frequencia 'Freq %', m.situacao 'Situação Final'
from aluno a, matricula m, disciplina d
where  a.ra = 4 and a.ra = m.ra and m.sigla = d.sigla and m.dataAno = 2021

--alunos reprovados
select a.ra 'RA Aluno', a.nome 'Nome Aluno', d.nome 'Disciplina',  m.nota1 'Nota 1', m.nota2 'Nota 2', m.notaSub 'Nota Sub', m.media 'Media', m.frequencia 'Freq %', m.situacao 'Situação Final'
from aluno a, matricula m, disciplina d
where m.situacao <> 'APROVADO' and a.ra = m.ra and m.sigla = d.sigla and m.dataAno = 2022

--todos os alunos
select a.ra 'RA aluno', a.nome 'Nome aluno', m.sigla 'Sigla disciplina', d.nome 'Nome Disciplina',m.nota1 'Nota 1° Bimestre', m.nota2 'Nota 2° Bimestre' , m.media 'Media final', m.frequencia 'Frequencia final', m.situacao 'Situação final'
from aluno a, matricula m, disciplina d
where a.ra = m.ra and m.sigla = d.sigla and m.dataAno = 2021
