--1--
  
CREATE FUNCTION calculer_prix_reservation(reservation_id INT)
RETURNS float
BEGIN
   DECLARE prix_total DECIMAL(10, 2);
   DECLARE nb_jours INT;
   DECLARE prix_par_jour DECIMAL(10, 2);

   SELECT DATEDIFF(date_fin, date_debut) INTO nb_jours
   FROM Reservations
   WHERE reservation_id = reservation_id;
   SELECT prix_par_jour INTO prix_par_jour
   FROM Destinations d
   JOIN Reservations r ON d.destination_id = r.destination_id
   WHERE r.reservation_id = reservation_id;
   SET prix_total = nb_jours * prix_par_jour;
   RETURN prix_total;
END;

2--

CREATE FUNCTION note_moyenne_destination(destination_id INT)
RETURNS float
BEGIN
   DECLARE moyenne DECIMAL(3, 2);

   
   SELECT AVG(note) INTO moyenne
   FROM Avis
   WHERE destination_id = destination_id;

   RETURN moyenne;
END;


3--1
 
CREATE PROCEDURE ajouter_client(
   IN nom_client VARCHAR(255),
   IN email_client VARCHAR(255),
   IN telephone_client VARCHAR(20)
)
BEGIN
  
   IF (SELECT COUNT(*) FROM Clients WHERE email = email_client) > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lemail existe déjà';
   ELSE   INSERT INTO Clients 
  
      VALUES (nom_client, email_client, telephone_client, NOW());
   END IF;
 

3--2
  
CREATE PROCEDURE ajouter_paiement(
   IN reservation_id INT,
   IN montant_paiement DECIMAL(10, 2)
)
BEGIN
   DECLARE montant_total DECIMAL(10, 2);
   DECLARE montant_paye DECIMAL(10, 2);
   DECLARE solde DECIMAL(10, 2);

    
   SELECT calculer_prix_reservation(reservation_id) INTO montant_total;

   
   SELECT SUM(montant) INTO montant_paye
   FROM Paiements
   WHERE reservation_id = reservation_id;
   SET solde = montant_total - montant_paye;
   IF montant_paiement > solde THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Le paiement dépasse le solde restant';
   ELSE
      INSERT INTO Paiements (reservation_id, montant, date_paiement)
      VALUES (reservation_id, montant_paiement, NOW());
   END IF;
END;

4--1
  
CREATE PROCEDURE verifier_montant_paiement(reservation_id INT, montant_paiement DECIMAL(10, 2))
BEGIN
   DECLARE montant_total DECIMAL(10, 2);
   DECLARE montant_paye DECIMAL(10, 2);
   DECLARE solde DECIMAL(10, 2);

    
   SELECT calculer_prix_reservation(reservation_id) INTO montant_total;
   SELECT SUM(montant) INTO montant_paye
   FROM Paiements
   WHERE reservation_id = reservation_id;   
   SET solde = montant_total - montant_paye; 
   IF montant_paiement > solde THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Le paiement dépasse le solde dû';
   END IF;
END 

4--2
 
CREATE TRIGGER apres_insertion_paiement
AFTER INSERT ON Paiements
FOR EACH ROW BEGIN
   DECLARE montant_total DECIMAL(10, 2);
   DECLARE montant_paye DECIMAL(10, 2);

   
   SELECT calculer_prix_reservation(NEW.reservation_id) INTO montant_total;
   SELECT SUM(montant) INTO montant_paye
   FROM Paiements
   WHERE reservation_id = NEW.reservation_id;
   IF montant_paye >= montant_total THEN
      UPDATE Reservations
      SET etat = 'confirmée';
      WHERE reservation_id = NEW.reservation_id;
   END IF;
END;
