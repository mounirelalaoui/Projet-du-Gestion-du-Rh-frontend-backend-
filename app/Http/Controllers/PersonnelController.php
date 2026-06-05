<?php

namespace App\Http\Controllers;

use App\Models\Personnel; //plus important
use App\Http\Resources\PersonnelResource;
use App\Http\Requests\StorePersonnelRequest;
use App\Http\Requests\UpdatePersonnelRequest;
use Illuminate\Http\Request;

class PersonnelController extends Controller
{
    use \App\Traits\ApiResponds;

    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = Personnel::with(['etablissement', 'specialites', 'diplomes'])
            ->when($request->filled('nom'), function($q) use ($request) {
                $q->where('nom', 'like', '%' . $request->nom . '%');
            })
            ->when($request->filled('cin'), function($q) use ($request) {
                $q->where('cin', $request->cin);
            })
            ->when($request->filled('idEtab'), function($q) use ($request) {
                $q->where('idEtab', $request->idEtab);
            })
            ->when($request->filled('type'), function($q) use ($request) {
                $q->where(function($sub) use ($request) {
                    $sub->where('type_personnel', $request->type)
                        ->orWhere('type', $request->type); // for backward compatibility if any
                });
            });

        // secure sorting
        $allowedSorts = ['nom', 'cin', 'created_at'];
        $sortBy = $request->filled('sort_by') && in_array($request->sort_by, $allowedSorts) 
            ? $request->sort_by 
            : 'created_at';
        $order = $request->order === 'desc' ? 'desc' : 'asc';

        $query->orderBy($sortBy, $order);

        $perPage = $request->per_page ?? 10;

        return PersonnelResource::collection(
            $query->paginate($perPage)
        );
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StorePersonnelRequest $request)
    {  
        $personnel = Personnel::create($request->validated());
        
        if ($request->has('specialites')) {
            $personnel->specialites()->sync($request->specialites);
        }
        if ($request->has('diplomes')) {
            $personnel->diplomes()->sync($request->diplomes);
        }
        
        return new PersonnelResource($personnel);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $p = Personnel::with(['etablissement','conges','absences', 'specialites', 'diplomes'])->findOrFail($id);

        return new PersonnelResource($p);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdatePersonnelRequest $request, string $id)
    {
        $p = Personnel::findOrFail($id);
        $p->update($request->validated());

        if ($request->has('specialites')) {
            $p->specialites()->sync($request->specialites);
        }
        if ($request->has('diplomes')) {
            $p->diplomes()->sync($request->diplomes);
        }

        return new PersonnelResource($p);
    }

    /** 
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
         $p = Personnel::findOrFail($id);
         $p->delete();
         return $this->success(null, 'Personnel supprimé avec succès');
    }

    /**
     * Import multiple personnels.
     */
    public function import(Request $request)
    {
        $request->validate([
            'personnels' => 'required|array',
        ]);

        $inserted = [];
        \Illuminate\Support\Facades\DB::transaction(function() use ($request, &$inserted) {
            foreach ($request->personnels as $data) {
                $personnel = Personnel::create($data);
                $inserted[] = $personnel;
            }
        });

        return $this->success(\App\Http\Resources\PersonnelResource::collection($inserted), 'Import réussi');
    }

    /**
     * Remove all resources from storage.
     */
    public function destroyAll()
    {
        Personnel::query()->delete();
        return $this->success(null, 'Tous les personnels ont été supprimés avec succès');
    }
}
