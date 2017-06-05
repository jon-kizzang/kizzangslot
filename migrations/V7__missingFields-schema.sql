ALTER TABLE SlotTournament ADD type ENUM('Daily','Weekly','Monthly','HalfDay') NOT NULL DEFAULT 'Daily';
ALTER TABLE SlotTournament ADD GameIDs SET('angrychefs','bankrollbandits','butterflytreasures','underseaworld','romancingriches','underseaworld2','oakinthekitchen','crusadersquest','mummysrevenge','ghosttreasures','penguinriches') NOT NULL;
ALTER TABLE SlotTournament ADD Title varchar(50);
