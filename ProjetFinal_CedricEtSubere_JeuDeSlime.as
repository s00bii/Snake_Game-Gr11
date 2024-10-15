/* 
Nom du programmeur: Subere Houssein Ali et Cédric Vercolier
Nom du fichier: ProjetFinal_CedricEtSubere_JeuDeSlime
Date: 2023/06/03
Titre: JeuDeSlime
Description:
Ce code met en place un jeu simple où le joueur contrôle un personnage de slime 
et tente de manger des fruits tout en évitant les obstacles. Le score du joueur
est enregistré et les meilleurs scores sont affichés. Le jeu prend également en
charge la sauvegarde et le chargement des données du joueur à partir d'un fichier XML.
*/

//Ouverture du paquetage
package{
	
	//Importations nécessaires
	import flash.display.*;
	//Importation pour le texte
	import flash.text.*;
	//Importation pour les événements
	import flash.events.*;
	//Importation pour les fonctions utilitaires
	import flash.utils.*;
	//Importation pour les touches du clavier
	import flash.ui.Keyboard;
	//Importation pour l'interaction avec le bureau
	import flash.desktop.*;
	//Importation pour les commandes système du fichier
	import flash.system.fscommand;
	//Importation pour les communications réseau
	import flash.net.*;

	//Classe principale du jeu
	public class ProjetFinal_CedricEtSubere_JeuDeSlime extends MovieClip {
	
		//Les paramètres de la grille
		var tailleDeGrille:int = 15; //Taille de la grille
		var offsetX:Number = 50.3; //Décalage horizontal
		var offsetY:Number = 135.0; //Décalage vertical
		var echelle:Number = 40.0; //Échelle
	
		//Array qui stockera l'état des obstacles et du joueur
		var carres:Array = new Array(tailleDeGrille); //Tableau pour les carrés
	
		//Coordonnées actuelles du joueur
		var joueurCoordX:int = 1; //Coordonnée X du joueur
		var joueurCoordY:int = 1; //Coordonnée Y du joueur
	
		//Coordonnées actuelles du fruit
		var fruitCoordX:int = 2; //Coordonnée X du fruit
		var fruitCoordY:int = 2; //Coordonnée Y du fruit
	
		//Suivre le score du joueur
		var score:int = 0; //Score du joueur
		
		//Chargeur du fichier XML et l'adresse du fichier XML
		var adresse:URLRequest = new URLRequest("ProjetFinal_CedricEtSubere_ListeDeJoueur.xml");
      	var chargeur:URLLoader = new URLLoader();
		
		//Liste des joueurs qui on joué ce jeu
		var joueurs:Array = new Array();

		//Indice du joueur en ce moment
		var joueurIndice:int = -1;
		
		//Suivre le dernier delta de temps.
		var dernierTemps:int;
		
		//État de pause du jeu.
		var jeuPause:Boolean;
		
		//Direction du joueur
			//0 -> haut
			//1 -> bas
			//2 -> gauche
			//3 -> droite
			
		//Commence vers la droite	
		var ddj:int = 3;
		
		//Utilisé pour calculer des nouvelles coordonnées
		var mouvementDiffs:Array = new Array(
			[0, -1], //Déplacement vers le haut
			[0, 1], //Déplacement vers le bas
			[-1, 0], //Déplacement vers la gauche
			[1, 0] //Déplacement vers la droite
		);
		
		//Ouverture de la fonction publique du jeu
    	public function ProjetFinal_CedricEtSubere_JeuDeSlime(){
			
			menuPrincip(); //Afficher le menu principal -------------------------- Change name
			chargeXMLData(); //Charger les données XML ------------------------
			carres = new Array(tailleDeGrille); //Tableau pour les carrés
			initArray(); //Initialiser le tableau
			initObstacles(); //Initialiser les obstacles
			
			//Restreindre les caractères dans la boîte de texte d'entrée utilisateur
			Debut.nomUtilisateur.restrict = "A-Z\\a-z";
			//Restreindre le nombre de caractères dans la boîte de texte d'entrée utilisateur
			Debut.nomUtilisateur.maxChars = 10;

			//Enregistrer l'événement appelé à chaque frame
			stage.addEventListener(Event.ENTER_FRAME, frame);

			//Enregistrer l'événement lorsque nous appuyons sur une touche (pour le mouvement)
			stage.addEventListener(KeyboardEvent.KEY_DOWN, gererInput);

			//Enregistrer l'événement lorsque nous appuyons sur le bouton Jouer
			Debut.btnJouer.addEventListener(MouseEvent.CLICK, jouer);

			//Enregistrer l'événement lorsque nous appuyons sur le bouton Rejouer
			Fin.btnRejouer.addEventListener(MouseEvent.CLICK, jouer);

			//Enregistrer l'événement lorsque nous appuyons sur le bouton Déconnecter
			Fin.btnDeconnecter.addEventListener(MouseEvent.CLICK, deconnecter);
			
		}//Fin de la fonction

		//Afficher le menu principal lorsque nous nous connectons
		function menuPrincip():void {
			
			Fin.visible = false; //Cacher l'arrière-plan foncé
			Debut.visible = true; //Afficher l'écran de début
			jeuPause = true; //Mettre le jeu en pause
			
		}//Fin de la fonction menuPrincip
		
        //Quand l'utilisateur appuit le bouton deconnection
		function deconnecter(event:MouseEvent):void
		{
			
			//Retourner à la fenetre d'ouverture
			menuPrincip();
			
		}//Fin de la fonction deconnecter
		
		//Charger les données du fichier XML qui contient les noms et les scores de chaque joueur (contient également le meilleur score)
		function chargeXMLData():void
		{
			
			chargeur.addEventListener(Event.COMPLETE, XMLDataChargeComplete);
			chargeur.load(adresse);
			
		}//Fin de la fonction chargeXMLData

		//Fonction appelée lorsque le chargement du fichier XML est terminé avec succès
		function XMLDataChargeComplete(event: Event):void
		{
			
			//Créer un objet XML à partir des données chargées
			var xml: XML = new XML(chargeur.data);
			//Récupérer la liste des joueurs du fichier XML
			var xmlListe: XMLList = xml.joueur;
			
			//Mettre à jour le tableau des joueurs
			for(var i:Number = 0; i < xmlListe.length(); i++){
				
				var nom:String = xmlListe[i].nom; //Récupérer le nom du joueur à l'index actuel
				var score:int= xmlListe[i].score; //Récupérer le score du joueur à l'index actuel
				joueurs.push([nom, score]); //Ajouter le nom et le score du joueur dans le tableau des joueurs
			}
			
		} //Fin de la fonction XMLDataLoadComplete

		//Fonction appelée lorsque le l'utilisateur appuye le bouton jouer
		function jouer(event:MouseEvent):void
		{
			//Récupére le nom saisi par l'utilisateur dans la zone de texte
			var nom:String = Debut.nomUtilisateur.text;
			
			//Ne rien faire si l'utilisateur n'a pas saisi de nom
			if (nom.length == 0)
			{
				//Affiche un message indiquant que l'utilisateur dot entrer un nom
				Debut.txtAffichage.text =("Entrez un nom d'utilsateur pour jouer!"); 
				return;
			}
			
			joueurIndice = -1; //Réinitialiser l'indice du joueur
			
			//Vérifier si le joueur existe dans la liste des joueurs
			for(var i:Number = 0; i < joueurs.length; i++)
			{
				//Si le nom du joueur correspond à celui saisi par l'utilisateur
				if (joueurs[i][0] == nom)
				{
					//Définir l'indice du joueur
					joueurIndice = i;
				}
			}
			
			//Définir le nom du joueur dans la boite texte du joueur
			txtNom.text = "Joueur: " + nom;
			
			//Si le joueur n'a pas été trouvé, l'ajouter à la liste des joueurs
			if (joueurIndice == -1)
			{
				//Ajouter le nom du joueur avec un score initial de 0 à la liste des joueurs
				joueurs.push([nom, 0]);
				//Définir l'indice du joueur nouvellement ajouté
				joueurIndice = joueurs.length - 1;
			}
			
			//Masquer l'écran de fin
			Fin.visible = false;
			//Masquer l'écran de début
			Debut.visible = false;
			
			//Enlever le jeu de mode pause
			jeuPause = false;
			//Afficher le joueur
			Joueur.visible = true;

			joueurCoordX = 1; //Définir Coordonnée X du joueur
			joueurCoordY = 1; //Définir Coordonnée Y du joueur
			ddj = 3; //Définir la direction de départ du joueur (droite)
			
			//Placer un fruit aléatoirement sur la grille
			placeFruit();
			
			//Réinitialiser le temps écoulé depuis le dernier mouvement
			dernierTemps = 0;
			//Réinitialiser le score du joueur
			score = 0;
			//Réinitialiser le texte du score affiché
			txtScoreActuel.text = "0";
			
			//Récupérer le meilleur score du joueur actuel dans la liste des joueurs
			var meilleurScore:int = joueurs[joueurIndice][1]; 
			//Afficher le meilleur score du joueur au début du jeu
			txtMeilleurScore.text = meilleurScore.toString(); //Rendre en string
			
		} //Fin de la fonction jouer
	
		
		//Appelée lorsqu'une nouvelle entrée clavier doit être gérée
		function gererInput(event:KeyboardEvent):void
		{ 
			if (event.keyCode == Keyboard.UP)  
			{ 
				ddj = 0; //Mettre la direction du joueur à 0 (haut)
			} 
			else if (event.keyCode == Keyboard.DOWN) 
			{
				ddj = 1; //Mettre la direction du joueur à 1 (bas)
			} 
			else if (event.keyCode == Keyboard.LEFT) 
			{
				ddj = 2; //Mettre la direction du joueur à 2 (gauche)
			} 
			else if (event.keyCode == Keyboard.RIGHT) 
			{
				ddj = 3; //Mettre la direction du joueur à 3 (droite)
			}
			
		} //Fin de la fonction gererInput
		
		//Appelée à chaque image pour mettre à jour la position du joueur
		private function frame(event:Event):void
		{			
			gererLogic(); //Appeler la fonction "gererLogic()" pour gérer la logique du jeu
			afficherScene(); //Appeler la fonction "afficherScene()" pour afficher la scène du jeu

		} //Fin de la fonction frame
		
		//Appelée à chaque image pour mettre à jour la position du joueur
		private function gererLogic():void
		{
			if (jeuPause) 
			{
				return; //Si le jeu est en pause, sortir de la fonction
			}
			
			//Exécuter la logique du joueur chaque seconde
			var nouveauTemps:int = getTimer();
			
			if (nouveauTemps - dernierTemps > 80) //Plus la valeur dans ce cas "80" est élevée, plus c'est lent
			{  
				//Mettre à jour les coordonnées du joueur en fonction de la direction actuelle (ddj)
				joueurCoordX += mouvementDiffs[ddj][0]; //Mise à jour de la coordonnée X du joueur
				joueurCoordY += mouvementDiffs[ddj][1]; //Mise à jour de la coordonnée Y du joueur
				dernierTemps = nouveauTemps; //Mettre à jour le temps dernierTemps avec le temps actuel
				
				//Vérifier si le joueur est mort
				if (!estPositionJoueurValide()) 
				{
					jeuPause = true; //Mettre le jeu en pause
					Joueur.visible = false; //Cacher l'élément graphique du joueur
					Fin.visible = true; //Afficher l'écran de fin de jeu
					
					Fin.txtScoreDuJeu.text = "Score Final: " + score.toString(); //Afficher le score final du joueur
					Fin.txtMeilleurScore.text = "Meilleur Score: " + joueurs[joueurIndice][1].toString(); //Afficher le meilleur score enregistré
					sortJoueursEtDisplay(); //Trier les joueurs et afficher les classements
				}
				
				//Vérifier si le joueur a mangé le fruit
				if (joueurCoordX == fruitCoordX && joueurCoordY == fruitCoordY) 
				{
					placeFruit(); //Placer un nouveau fruit aléatoirement sur la scène
					score += 1; //Augmenter le score du joueur de 1
					
					var meilleurScore:int = joueurs[joueurIndice][1]; //Récupérer le meilleur score actuel
					
					//Si score est plus grand que meilleurScore la valeur est remplacée
					if (score > meilleurScore) 
					{
						joueurs[joueurIndice][1] = score; //Mettre à jour le meilleur score avec le nouveau score du joueur
						meilleurScore = score; //Mettre à jour la variable locale du meilleur score
					}
					
					txtScoreActuel.text = score.toString(); //Afficher le score actuel du joueur
					txtMeilleurScore.text = meilleurScore.toString(); //Afficher le meilleur score du joueur
				}
			}
		}//Fin de la fonction gererLogic
		
		//Trier la liste des joueurs et afficher les meilleurs scores globaux
		private function sortJoueursEtDisplay():void
		{
			var triage:Array = joueurs.slice(); //Copier la liste des joueurs dans un nouvel tableau
			
			//Vérifier si le tableau est trié à chaque itération
			var trier: Boolean = false;
			
			//Lorsque trier est true;
			while(!trier)
			{
				//Échanger l'élément actuel avec l'élément suivant si nécessaire
				for(var i:Number = 0; i < joueurs.length-1; i++)
				{
					//Comparer les scores des joueurs actuel et suivant
					if (triage[i][1] < triage[i+1][1])
					{
						var copy:Array = triage[i]; //Stocker l'élément actuel dans une variable temporaire
						triage[i] = triage[i+1]; //Remplacer l'élément actuel par l'élément suivant
						triage[i+1] = copy; //Remplacer l'élément suivant par l'élément actuel (stocké dans la variable temporaire)
						break; //Sortir de la boucle for car un échange a été effectué
					}
				} 
			
				//Réinitialiser trier à true
				trier = true;
				
				//Vérifier si tous les éléments sont triés
				for(var j:Number = 0; j < joueurs.length-1; j++)
				{
					// Si un élément est plus petit que l'élément suivant, le tableau n'est pas encore trié
					if (triage[j][1] < triage[j+1][1])
					{
						trier = false //Réinitialiser trier à false
					}
				} 
				
			}//Fin du While loop
			
			//Afficher les noms triés dans la zone de texte
			var texteFinal:String = "";
			
			//Inscrire des valeurs pour trouver le numero, le nom et le score d'un joueur
			for(var k:Number = 0; k < joueurs.length; k++)
			{
				texteFinal += (k + 1) + ") " + triage[k][0] + ": " + triage[k][1] + "\n"; //Ajouter le numéro, le nom et le score du joueur au texte final
			} 
			Fin.txtListeDesJoueurs.text = texteFinal; //Afficher le texte final dans la zone de texte dédiée
			
		}//Fin de la fonction sortJoueursEtDisplay
		
		//Met à jour la position du joueur et affiche les objets dans la grille
		private function afficherScene():void
		{
			Joueur.x = joueurCoordX * echelle + offsetX; //Met à jour la position horizontale du joueur
			Joueur.y = joueurCoordY * echelle + offsetY; //Met à jour la position verticale du joueur

			Fruit.x = fruitCoordX * echelle + offsetX; //Met à jour la position horizontale du fruit		
			Fruit.y = fruitCoordY * echelle + offsetY; //Met à jour la position verticale du fruit
			
		}//Fin de la fonction afficherScence
		
		//Vérifie s'il faut créer un obstacle à une coordonnée spécifique
		private function creerObstacle(x:int, y: int):Boolean 
		{
			//Version avec des coordonnées spécifiques pour creer le croix
			return (x == 7 && y > 2 && y < 12) || (y == 7 && x > 2 && x < 12); 
			
		}//Fin du fonction creerObstacle
		
		//Vérifie si la position actuelle du joueur est valide
		private function estPositionJoueurValide():Boolean 
		{
			var coordsValid:Boolean = joueurCoordX >= 0 && joueurCoordX < 15 && joueurCoordY >= 0 && joueurCoordY < 15; //Vérifie si les coordonnées du joueur sont dans les limites de la grille
			var posValid:Boolean = coordsValid; //La position est valide si les coordonnées sont valides
			
			if (coordsValid == true) 
			{
				//Vérifie si la case aux coordonnées actuelles contient un obstacle (représenté par 1)
				posValid = posValid && carres[joueurCoordX][joueurCoordY] != 1; 
			}
			
			return posValid; //Retourne la validité de la position du joueur
			
		}//Fin du fonction estPositionJoueurValide
		
		//Initialise le tableau de grille avec les carrés par défaut
		private function initArray():void 
		{
			//Parcourir les lignes de la grille
			for(var x:Number = 0; x < tailleDeGrille; x++) 
			{
				//Initialise un sous-tableau pour chaque rangée de la grille
				carres[x] = new Array(tailleDeGrille); 
				
				//Parcourir les colonnes de la grille
				for (var y:Number = 0; y < tailleDeGrille; y++) 
				{
					//Vérifier si un obstacle doit être créé à la position actuelle
					if (creerObstacle(x, y)) 
					{
						carres[x][y] = 1; //Crée un obstacle à la position actuelle de la grille
					} 
					else 
					{
						carres[x][y] = 0; //Laisse la position actuelle de la grille vide (sans obstacle)
					}
  				}
			}
			
		}//Fin de la fonction initArray
		
		//Initialise les obstacles et les ajoute dans le monde
		private function initObstacles():void 
		{
			//Parcourir les lignes de la grille
			for(var x:Number = 0; x < tailleDeGrille; x++) 
			{
				//Parcourir les colonnes de la grille
				for (var y:Number = 0; y < tailleDeGrille; y++) 
				{
					//Vérifier si la case de la grille contient un obstacle (valeur 1)
  					if (carres[x][y] == 1) 
					{
						var debutX:Number = echelle * x + offsetX; //Coordonnée X de départ du carré de l'obstacle
						var debutY:Number = echelle * y + offsetY; //Coordonnée Y de départ du carré de l'obstacle
						
						var s:Sprite = new Sprite(); //Crée un nouvel objet Sprite pour représenter l'obstacle
						s.graphics.beginFill(0xFF0000); //Définit la couleur de remplissage du carré de l'obstacle
						s.graphics.drawRect(debutX, debutY, echelle, echelle); //Dessine un carré pour représenter l'obstacle
						s.graphics.endFill(); //Termine le dessin du carré
						
						this.addChildAt(s, 1); //Ajoute l'obstacle en tant qu'enfant de l'élément graphique principal de la scène
					}
  				}
			}
			
		}//Fin de la fonction initObstacles
		
		//Place un fruit aléatoirement sur la carte (pas à l'intérieur d'un obstacle)
		private function placeFruit():void 
		{
			var posValid:Boolean = false; //Variable pour vérifier la validité de la position du fruit
			
			//Boucle jusqu'à ce qu'une position valide soit trouvée pour le fruit
			while (!posValid) 
			{
				fruitCoordX = Math.floor(Math.random() * (tailleDeGrille - 2)); //Coordonnée X aléatoire du fruit
				fruitCoordY = Math.floor(Math.random() * (tailleDeGrille - 2)); //Coordonnée Y aléatoire du fruit
				
				posValid = carres[fruitCoordX][fruitCoordY] != 1; //Vérifie si la position du fruit ne correspond pas à celle d'un obstacle
    
			}
			
		}//Fin de la fonction placeFruit
		
	} //Fin de la classe
	
} //Fin du paquetage