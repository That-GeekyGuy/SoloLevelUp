-- SoloLevelUp — starter Achievement catalog (FR-6.1). The reference video
-- shows 44 slots; this seeds a first batch covering each unlock_rule type so
-- the mechanic is exercised end-to-end. Add more anytime via the MCP
-- add_achievement-style insert (service_role) — the catalog is not tied to
-- app releases (NFR-7.1).
insert into public.achievements (key, name, description, icon_ref, unlock_rule, sort_order) values
  ('first_quest',        'First Step',        'Complete your first quest.',                         'footprint',  '{"type":"quest_completions_total","threshold":1}',   1),
  ('ten_quests',         'Getting Started',    'Complete 10 quests.',                                 'check',      '{"type":"quest_completions_total","threshold":10}',  2),
  ('fifty_quests',       'Grinder',            'Complete 50 quests.',                                 'check',      '{"type":"quest_completions_total","threshold":50}',  3),
  ('hundred_quests',     'Centurion',          'Complete 100 quests.',                                'check',      '{"type":"quest_completions_total","threshold":100}', 4),
  ('streak_3',           'On A Roll',          'Reach a 3-day streak on any quest.',                  'flame',      '{"type":"streak_reached","threshold":3}',            5),
  ('streak_7',           'One Week Strong',    'Reach a 7-day streak on any quest.',                  'flame',      '{"type":"streak_reached","threshold":7}',            6),
  ('streak_14',          'Two Weeks Deep',     'Reach a 14-day streak on any quest.',                 'flame',      '{"type":"streak_reached","threshold":14}',           7),
  ('streak_30',          'Unshakeable',        'Reach a 30-day streak on any quest.',                 'flame',      '{"type":"streak_reached","threshold":30}',           8),
  ('discipline_70',      'Disciplined',        'Reach 70 Discipline.',                                'lock',       '{"type":"stat_reached","stat":"discipline","threshold":70}', 9),
  ('strength_70',        'Strong',             'Reach 70 Strength.',                                  'strength',   '{"type":"stat_reached","stat":"strength","threshold":70}',   10),
  ('wisdom_70',          'Wise',               'Reach 70 Wisdom.',                                    'wisdom',     '{"type":"stat_reached","stat":"wisdom","threshold":70}',     11),
  ('focus_70',           'Focused',            'Reach 70 Focus.',                                     'focus',      '{"type":"stat_reached","stat":"focus","threshold":70}',      12),
  ('confidence_70',      'Self-Assured',       'Reach 70 Confidence.',                                'confidence', '{"type":"stat_reached","stat":"confidence","threshold":70}', 13),
  ('overall_90',         'Elite',              'Reach 90 Overall Rise Rating.',                       'star',       '{"type":"stat_reached","stat":"overall","threshold":90}',    14),
  ('reader_5',           'Bookworm',           'Finish 5 Daily Learning summaries.',                  'book',       '{"type":"learning_items_done","threshold":5}',       15),
  ('reader_20',          'Well Read',          'Finish 20 Daily Learning summaries.',                 'book',       '{"type":"learning_items_done","threshold":20}',      16),
  ('challenge_complete', 'Rise Complete',      'Finish a full challenge, start to finish.',           'trophy',     '{"type":"challenge_completed"}',                     17)
on conflict (key) do nothing;
