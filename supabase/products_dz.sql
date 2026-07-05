-- ============================================================
--  MARKETPLACE — Produits de parapharmacie / orthopédie (DZ)
--  Les 5 produits photographiés utilisent des images locales
--  (assets/images/products/...). À exécuter dans Supabase → SQL Editor.
-- ============================================================

delete from public.products;

insert into public.products
  (name, brand, category, description, price, original_price, image, rating, review_count, seller, phone) values
  -- ===== Produits avec photo (assets locaux) =====
  ('Genouillère de compression', 'OrthoPlus', 'Orthopédie', 'Genouillère tricotée respirante avec sangles de serrage réglables. Stabilise le genou pour le sport ou après une entorse.', 3500, 4200, 'assets/images/products/genouillere.jpg', 4.7, 128, 'OrthoPlus Alger', '0555100001'),
  ('Chevillère de maintien', 'BoldFit', 'Orthopédie', 'Chevillère de compression avec sangle croisée. Stabilise la cheville, améliore les performances, tissu respirant.', 2900, 3400, 'assets/images/products/chevillere.jpg', 4.6, 94, 'ParaSanté Oran', '0555100004'),
  ('Semelles anti-douleur Scholl', 'Scholl', 'Orthopédie', 'Semelles In-Balance genou et talon. Action 3-en-1 : absorption des chocs, stabilisation et répartition de la pression. Prouvé cliniquement.', 2600, null, 'assets/images/products/semelles.jpg', 4.8, 176, 'ParaSanté Oran', '0555100017'),
  ('Brosse à dents électrique', 'SonicClean', 'Hygiène', 'Brosse à dents électrique sonique rechargeable avec plusieurs têtes de rechange. Nettoyage en profondeur, plusieurs modes.', 3900, 4900, 'assets/images/products/brosse_dents.jpg', 4.5, 88, 'MediShop DZ', '0555100018'),
  ('Sacoche isotherme insuline', 'CoolMed', 'Diagnostic', 'Sacoche de transport isotherme pour insuline avec affichage de la température et 2 pochettes de gel. Idéale pour les voyages.', 4500, null, 'assets/images/products/sacoche_insuline.jpg', 4.7, 51, 'MediShop DZ', '0555100019'),
  -- ===== Reste du catalogue (icône par catégorie) =====
  ('Ceinture lombaire', 'BackFit', 'Orthopédie', 'Soutien lombaire pour soulager les douleurs du bas du dos et maintenir la posture.', 4800, 5500, null, 4.6, 152, 'OrthoPlus Alger', '0555100003'),
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
