-- ============================================================
--  MARKETPLACE — Produits parapharmacie / orthopédie (DZ)
--  Les produits photographiés utilisent des images locales
--  (assets/images/products/...). À exécuter dans Supabase → SQL Editor.
-- ============================================================

delete from public.products;

insert into public.products
  (name, brand, category, description, price, original_price, image, rating, review_count, seller, phone) values
  -- ===== Produits AVEC photo (assets locaux) =====
  ('Genouillère de compression', 'OrthoPlus', 'Orthopédie', 'Genouillère tricotée respirante avec sangles de serrage réglables. Stabilise le genou pour le sport ou après une entorse.', 3500, 4200, 'assets/images/products/genouillere.jpg', 4.7, 128, 'OrthoPlus Alger', '0555100001'),
  ('Chevillère de maintien', 'BoldFit', 'Orthopédie', 'Chevillère de compression avec sangle croisée. Stabilise la cheville, tissu respirant.', 2900, 3400, 'assets/images/products/chevillere.jpg', 4.6, 94, 'ParaSanté Oran', '0555100004'),
  ('Semelles anti-douleur Scholl', 'Scholl', 'Orthopédie', 'Semelles In-Balance genou et talon. Action 3-en-1 : absorption des chocs, stabilisation et répartition de la pression.', 2600, null, 'assets/images/products/semelles.jpg', 4.8, 176, 'ParaSanté Oran', '0555100017'),
  ('Orthèse de genou articulée', 'Medi', 'Orthopédie', 'Orthèse rigide articulée avec amplitude réglable. Immobilisation et rééducation du genou après opération ou entorse grave.', 12000, 14000, 'assets/images/products/orthese_genou.png', 4.9, 37, 'OrthoPlus Alger', '0555100020'),
  ('Ceinture lombaire', 'BackFit', 'Orthopédie', 'Ceinture de soutien lombaire pour soulager les douleurs du bas du dos et maintenir la posture.', 4800, 5500, 'assets/images/products/ceinture_lombaire.png', 4.6, 152, 'OrthoPlus Alger', '0555100003'),
  ('Correcteur hallux valgus', 'FootCare', 'Orthopédie', 'Séparateur et correcteur d''orteils en silicone pour soulager l''oignon (hallux valgus). Lot de 2.', 1200, null, 'assets/images/products/correcteur_orteils.png', 4.4, 63, 'ParaSanté Oran', '0555100021'),
  ('Sacoche isotherme insuline', 'CoolMed', 'Diagnostic', 'Sacoche de transport isotherme pour insuline avec affichage de la température et 2 pochettes de gel. Idéale pour les voyages.', 4500, null, 'assets/images/products/sacoche_insuline.png', 4.7, 51, 'MediShop DZ', '0555100019'),
  ('Brosse à dents électrique', 'SonicClean', 'Hygiène', 'Brosse à dents électrique sonique rechargeable avec plusieurs têtes de rechange. Nettoyage en profondeur.', 3900, 4900, 'assets/images/products/brosse_dents.jpg', 4.5, 88, 'MediShop DZ', '0555100018'),
  ('Dentifrice Colgate', 'Colgate', 'Hygiène', 'Dentifrice protection caries au fluor. Fraîcheur longue durée. Tube 100ml.', 250, null, 'assets/images/products/dentifrice.png', 4.5, 231, 'ParaSanté Oran', '0555100022'),
  ('Savon antiseptique Dettol', 'Dettol', 'Hygiène', 'Savon liquide antibactérien pour les mains. Élimine 99,9% des germes. Flacon pompe.', 550, null, 'assets/images/products/savon_dettol.png', 4.6, 198, 'ParaSanté Oran', '0555100023'),
  ('Bonnet chirurgical (lot)', 'MediWear', 'Hygiène', 'Lot de bonnets/charlottes chirurgicaux réutilisables, tissu respirant, plusieurs coloris.', 900, null, 'assets/images/products/bonnet_chirurgical.png', 4.3, 44, 'MediShop DZ', '0555100024'),
  ('Pistolet de massage', 'RelaxPro', 'Bien-être', 'Pistolet de massage musculaire percussif rechargeable avec plusieurs embouts et vitesses. Récupération et détente.', 8500, 11000, 'assets/images/products/pistolet_massage.png', 4.8, 142, 'MediShop DZ', '0555100025'),
  ('Ventouses de massage', 'RelaxPro', 'Bien-être', 'Set de ventouses pour massage et thérapie (cupping). Améliore la circulation et détend les muscles.', 1900, null, 'assets/images/products/ventouses.png', 4.4, 76, 'ParaSanté Oran', '0555100026'),
  -- ===== Reste du catalogue (icône par catégorie) =====
  ('Coussin anti-escarres', 'ComfortMed', 'Orthopédie', 'Mousse à mémoire de forme pour prévenir les escarres chez les personnes alitées.', 6800, null, null, 4.8, 40, 'MediShop DZ', '0555100005'),
  ('Bas de contention', 'VenoSoft', 'Orthopédie', 'Classe 2, améliore la circulation veineuse et réduit les jambes lourdes.', 3300, null, null, 4.3, 71, 'ParaSanté Oran', '0555100006'),
  ('Tensiomètre au bras', 'Omron', 'Diagnostic', 'Tensiomètre électronique automatique au bras, écran large, précision clinique.', 5500, 6500, null, 4.9, 210, 'MediShop DZ', '0555100007'),
  ('Thermomètre infrarouge', 'Beurer', 'Diagnostic', 'Thermomètre frontal sans contact, mesure en 1 seconde.', 3200, null, null, 4.6, 143, 'MediShop DZ', '0555100008'),
  ('Oxymètre de pouls', 'Contec', 'Diagnostic', 'Mesure la saturation en oxygène (SpO2) et la fréquence cardiaque.', 2500, 3000, null, 4.5, 98, 'MediShop DZ', '0555100009'),
  ('Glucomètre + bandelettes', 'Accu-Chek', 'Diagnostic', 'Lecteur de glycémie complet pour le suivi du diabète à domicile.', 4200, null, null, 4.7, 117, 'ParaSanté Oran', '0555100010'),
  ('Fauteuil roulant pliable', 'MobiCare', 'Mobilité', 'Léger et pliable, freins de sécurité, repose-pieds réglables.', 28000, null, null, 4.6, 33, 'MediShop DZ', '0555100011'),
  ('Béquilles réglables', 'MobiCare', 'Mobilité', 'Paire en aluminium, hauteur réglable, embouts antidérapants.', 3800, null, null, 4.4, 52, 'OrthoPlus Alger', '0555100012'),
  ('Déambulateur', 'MobiCare', 'Mobilité', 'Cadre de marche pliable avec poignées ergonomiques.', 9500, null, null, 4.5, 27, 'MediShop DZ', '0555100013'),
  ('Canne anglaise', 'MobiCare', 'Mobilité', 'En aluminium avec appui-bras, légère et réglable.', 1800, null, null, 4.2, 45, 'OrthoPlus Alger', '0555100014'),
  ('Gel hydroalcoolique 500ml', 'CleanMed', 'Hygiène', 'Désinfectant pour les mains à 70% d''alcool.', 450, null, null, 4.3, 189, 'ParaSanté Oran', '0555100015'),
  ('Masques FFP2 (boîte de 20)', 'SafeAir', 'Hygiène', 'Haute filtration, confortables pour un usage prolongé.', 1200, 1500, null, 4.6, 204, 'MediShop DZ', '0555100016');

delete from public.promo_offers;
insert into public.promo_offers (title, discount_text, delivery_text, promo_code, color_hex) values
  ('Offre spéciale', '-20% Orthopédie', 'Livraison partout en Algérie', 'ORTHO20', '#6C5FE0');
