-- ============================================================
--  MARKETPLACE — Produits de parapharmacie / orthopédie (DZ)
--  Remplace les médicaments par du matériel médical.
--  À exécuter dans Supabase → SQL Editor.
-- ============================================================

-- On repart d'un catalogue propre
delete from public.products;

insert into public.products
  (name, brand, category, description, price, original_price, image, rating, review_count, seller, phone) values
  ('Genouillère ligamentaire', 'OrthoPlus', 'Orthopédie', 'Genouillère de maintien avec baleines latérales pour stabiliser le genou après entorse ou pour la pratique sportive.', 3500, 4200, null, 4.7, 128, 'OrthoPlus Alger', '0555100001'),
  ('Attelle de poignet', 'MediCare', 'Orthopédie', 'Attelle rigide ajustable pour immobiliser le poignet en cas de tendinite ou de syndrome du canal carpien.', 2200, null, null, 4.5, 86, 'ParaSanté Oran', '0555100002'),
  ('Ceinture lombaire', 'BackFit', 'Orthopédie', 'Ceinture de soutien lombaire pour soulager les douleurs du bas du dos et maintenir la posture.', 4800, 5500, null, 4.6, 152, 'OrthoPlus Alger', '0555100003'),
  ('Orthèse de cheville', 'MediCare', 'Orthopédie', 'Chevillère de compression avec sangles croisées pour stabiliser la cheville après une foulure.', 2900, null, null, 4.4, 64, 'ParaSanté Oran', '0555100004'),
  ('Coussin anti-escarres', 'ComfortMed', 'Orthopédie', 'Coussin en mousse à mémoire de forme pour prévenir les escarres chez les personnes alitées.', 6800, null, null, 4.8, 40, 'MediShop DZ', '0555100005'),
  ('Bas de contention (paire)', 'VenoSoft', 'Orthopédie', 'Bas de contention classe 2 pour améliorer la circulation veineuse et réduire les jambes lourdes.', 3300, null, null, 4.3, 71, 'ParaSanté Oran', '0555100006'),
  ('Tensiomètre au bras', 'Omron', 'Diagnostic', 'Tensiomètre électronique automatique au bras, écran large, mémoire de mesures. Précision clinique.', 5500, 6500, null, 4.9, 210, 'MediShop DZ', '0555100007'),
  ('Thermomètre infrarouge', 'Beurer', 'Diagnostic', 'Thermomètre frontal sans contact, mesure en 1 seconde, idéal pour toute la famille.', 3200, null, null, 4.6, 143, 'MediShop DZ', '0555100008'),
  ('Oxymètre de pouls', 'Contec', 'Diagnostic', 'Oxymètre de doigt mesurant la saturation en oxygène (SpO2) et la fréquence cardiaque.', 2500, 3000, null, 4.5, 98, 'MediShop DZ', '0555100009'),
  ('Glucomètre + bandelettes', 'Accu-Chek', 'Diagnostic', 'Lecteur de glycémie complet avec bandelettes et autopiqueur pour le suivi du diabète à domicile.', 4200, null, null, 4.7, 117, 'ParaSanté Oran', '0555100010'),
  ('Fauteuil roulant pliable', 'MobiCare', 'Mobilité', 'Fauteuil roulant léger et pliable, freins de sécurité, repose-pieds réglables. Disponible en location.', 28000, null, null, 4.6, 33, 'MediShop DZ', '0555100011'),
  ('Béquilles réglables (paire)', 'MobiCare', 'Mobilité', 'Paire de béquilles axillaires en aluminium, hauteur réglable, embouts antidérapants.', 3800, null, null, 4.4, 52, 'OrthoPlus Alger', '0555100012'),
  ('Déambulateur', 'MobiCare', 'Mobilité', 'Cadre de marche pliable avec poignées ergonomiques pour aider à la marche et à l''équilibre.', 9500, null, null, 4.5, 27, 'MediShop DZ', '0555100013'),
  ('Canne anglaise', 'MobiCare', 'Mobilité', 'Canne de marche en aluminium avec appui-bras, légère et réglable en hauteur.', 1800, null, null, 4.2, 45, 'OrthoPlus Alger', '0555100014'),
  ('Gel hydroalcoolique 500ml', 'CleanMed', 'Hygiène', 'Gel désinfectant pour les mains à 70% d''alcool, action rapide contre les bactéries et virus.', 450, null, null, 4.3, 189, 'ParaSanté Oran', '0555100015'),
  ('Masques FFP2 (boîte de 20)', 'SafeAir', 'Hygiène', 'Masques de protection respiratoire FFP2, haute filtration, confortables pour un usage prolongé.', 1200, 1500, null, 4.6, 204, 'MediShop DZ', '0555100016');

-- Offre mise en avant sur la bannière
delete from public.promo_offers;
insert into public.promo_offers (title, discount_text, delivery_text, promo_code, color_hex) values
  ('Offre spéciale', '-20% Orthopédie', 'Livraison partout en Algérie', 'ORTHO20', '#6C5FE0');
