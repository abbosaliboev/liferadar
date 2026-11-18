"""Reject general commentary without inventing dates or affected facilities."""
import re


def general_traffic_commentary(text):
    recurring = re.search(r'주말마다|매주|평소|반복되고|반복된다|반복돼|불편을\s*(?:겪|호소)', text)
    dated = re.search(r'20\d{2}[-년.]\s*\d{1,2}[-월.]\s*\d{1,2}|\d{1,2}월\s*\d{1,2}일|오늘|내일|모레', text)
    notice = re.search(r'(?:통제|우회|무정차|폐쇄)(?:를|는|가|될|할)?\s*(?:예정|실시|시행|한다|된다|중|유지|해제)|이용\s*제한', text)
    return bool(recurring and not (dated and notice))


def publishable_event_impact(impact):
    if impact['type'] == 'STRIKE':
        return True
    if not impact['period']['start'].get('date'):
        return False
    # Region-only stories are not personal travel notices. Mapping to the
    # user's route remains the app's responsibility.
    if not any(s.get('reference_id') or
               (s.get('raw') and s['raw'] != s.get('region'))
               for s in impact['scope']):
        return False
    pattern = {
        'ROAD_CLOSURE': r'(?:도로|차량|대로|구간).*통제',
        'BUS_DETOUR': r'버스.*우회',
        'STOP_SKIP': r'무정차',
        'STATION_RESTRICTION': r'출입구.*폐쇄|역.*이용 제한',
        'CONGESTION_FORECAST': r'(?:교통|차량|보행).*혼잡.*(?:예상|전망)',
    }.get(impact['type'])
    return bool(pattern and any(
        not general_traffic_commentary(e.get('quote', '')) and
        re.search(pattern, e.get('quote', '')) for e in impact['evidence']))
